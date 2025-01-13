// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import 'forge-std/Test.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {ERC20} from '../mock/ERC20.sol';
import {PayloadsControllerCore, IPayloadsControllerCore} from '../../src/contracts/payloads/PayloadsControllerCore.sol';
import {Executor, IExecutor} from '../../src/contracts/payloads/Executor.sol';
import {IWithGuardian} from 'solidity-utils/contracts/access-control/interfaces/IWithGuardian.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {PayloadTest} from './utils/PayloadTest.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';

contract PayloadsControllerMock is PayloadsControllerCore {
  function queue(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel,
    uint40 proposalVoteActivationTimestamp
  ) external {
    _queuePayload(payloadId, accessLevel, proposalVoteActivationTimestamp);
  }
}

contract PayloadsControllerCoreTest is Test {
  address public constant ADMIN = address(65536 + 123);
  address public constant GUARDIAN = address(65536 + 1234);
  address public constant ORIGIN_FORWARDER = address(123456);
  address public constant PAYLOAD_PORTAL = address(987312);
  uint256 public constant YES_THRESHOLD = 1;

  uint256 public constant EXPIRATION_DELAY = 35 days;

  TransparentProxyFactory public proxyFactory;

  IERC20 public testToken;

  // payload registry
  address public constant approvedPayloadsRegistry =
    0xD1b1336608F2410cA46dD8C13843FBFAF1EEe923;
  // base slot
  uint256 public constant payloadBaseSlot = 53;

  // executors
  IExecutor public shortExecutor;
  IExecutor public longExecutor;

  IPayloadsControllerCore.UpdateExecutorInput public executor1 =
    IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1 days,
        executor: address(shortExecutor)
      })
    });

  IPayloadsControllerCore.UpdateExecutorInput public executor2 =
    IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 10 days,
        executor: address(longExecutor)
      })
    });

  IPayloadsControllerCore.UpdateExecutorInput public executor3 =
    IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1 days,
        executor: address(longExecutor)
      })
    });

  // payloads controllers
  PayloadsControllerMock public payloadsControllerImpl;
  PayloadsControllerMock public payloadsController;

  // bridge aggregator

  // events
  event GuardianUpdated(address oldGuardian, address newGuardian);
  event PayloadPortalUpdated(address newPayloadPortal);
  event ExecutorSet(
    PayloadsControllerUtils.AccessControl indexed accessLevel,
    address indexed executor,
    uint40 delay
  );
  event PayloadCreated(
    uint40 indexed payloadId,
    address indexed creator,
    IPayloadsControllerCore.ExecutionAction[] actions,
    PayloadsControllerUtils.AccessControl indexed maximumAccessLevelRequired
  );
  event PayloadQueued(uint40 payloadId);
  event PayloadCancelled(uint40 payloadId);

  function _getSimpleAction(
    address target
  ) internal pure returns (IPayloadsControllerCore.ExecutionAction memory) {
    return
      IPayloadsControllerCore.ExecutionAction({
        target: target,
        value: 0,
        signature: 'execute()',
        callData: bytes(''),
        withDelegateCall: true,
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1
      });
  }

  function setUp() public {
    testToken = IERC20(address(new ERC20('Test', 'TST')));
    proxyFactory = new TransparentProxyFactory();

    // payloadsController
    payloadsControllerImpl = new PayloadsControllerMock();
    // executors
    shortExecutor = new Executor();
    longExecutor = new Executor();
    executor1.executorConfig.executor = address(shortExecutor);
    executor2.executorConfig.executor = address(longExecutor);

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](2);
    executors[0] = executor1;
    executors[1] = executor2;

    address payloadsControllerProxy = proxyFactory.create(
      address(payloadsControllerImpl),
      ProxyAdmin(ADMIN),
      abi.encodeWithSelector(
        payloadsControllerImpl.initialize.selector,
        address(this),
        GUARDIAN,
        executors
      )
    );

    // // give ownership of executors to PayloadsController
    Ownable ownableShort = Ownable(address(shortExecutor));
    Ownable ownableLong = Ownable(address(longExecutor));
    ownableShort.transferOwnership(payloadsControllerProxy);
    ownableLong.transferOwnership(payloadsControllerProxy);

    payloadsController = PayloadsControllerMock(
      payable(payloadsControllerProxy)
    );
  }

  // test Getters
  function testPayloadCount() public {
    assertEq(payloadsController.getPayloadsCount(), 0);
  }

  function testGetExecutorSettingsByAccessControl() public {
    assertEq(
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_1
        )
        .executor,
      address(shortExecutor)
    );
    assertEq(
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_2
        )
        .executor,
      address(longExecutor)
    );
    assertEq(
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_1
        )
        .delay,
      executor1.executorConfig.delay
    );
    assertEq(
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_2
        )
        .delay,
      executor2.executorConfig.delay
    );
  }

  function testGuardian() public {
    assertEq(IWithGuardian(address(payloadsController)).guardian(), GUARDIAN);
  }

  // test Setters
  function testUpdateExecutorsWhenOwner() public {
    IExecutor newExecutor = new Executor();
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory newExecutors = new IPayloadsControllerCore.UpdateExecutorInput[](
        1
      );
    newExecutors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: uint40(1 days),
        executor: address(newExecutor)
      })
    });

    vm.expectEmit(true, true, true, true);
    emit ExecutorSet(
      newExecutors[0].accessLevel,
      newExecutors[0].executorConfig.executor,
      newExecutors[0].executorConfig.delay
    );
    payloadsController.updateExecutors(newExecutors);

    assertEq(
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_1
        )
        .executor,
      newExecutors[0].executorConfig.executor
    );
    assertEq(
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_1
        )
        .delay,
      newExecutors[0].executorConfig.delay
    );
    assertEq(
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_2
        )
        .executor,
      executor2.executorConfig.executor
    );
    assertEq(
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_2
        )
        .delay,
      executor2.executorConfig.delay
    );
  }

  function testUpdateExecutorsWhenDelayToSmall() public {
    IExecutor newExecutor = new Executor();

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory newExecutors = new IPayloadsControllerCore.UpdateExecutorInput[](
        1
      );
    newExecutors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1,
        executor: address(newExecutor)
      })
    });

    vm.expectRevert(bytes(Errors.INVALID_EXECUTOR_DELAY));
    payloadsController.updateExecutors(newExecutors);
  }

  function testUpdateExecutorsWhenDelayToBig() public {
    IExecutor newExecutor = new Executor();

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory newExecutors = new IPayloadsControllerCore.UpdateExecutorInput[](
        1
      );
    newExecutors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 11 days,
        executor: address(newExecutor)
      })
    });

    vm.expectRevert(bytes(Errors.INVALID_EXECUTOR_DELAY));
    payloadsController.updateExecutors(newExecutors);
  }

  function testUpdateExecutorsWhenIncorrectAccessLevel() public {
    IExecutor newExecutor = new Executor();

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory newExecutors = new IPayloadsControllerCore.UpdateExecutorInput[](
        1
      );
    newExecutors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_null,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1 days,
        executor: address(newExecutor)
      })
    });

    vm.expectRevert(bytes(Errors.INVALID_EXECUTOR_ACCESS_LEVEL));
    payloadsController.updateExecutors(newExecutors);
  }

  function testUpdateExecutorWhenExecutor0Address() public {
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory newExecutors = new IPayloadsControllerCore.UpdateExecutorInput[](
        1
      );
    newExecutors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1 days,
        executor: address(0)
      })
    });

    vm.expectRevert(bytes(Errors.INVALID_EXECUTOR_ADDRESS));
    payloadsController.updateExecutors(newExecutors);
  }

  function testUpdateExecutorWhenAlreadySetAsLevel2() public {
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory newExecutors = new IPayloadsControllerCore.UpdateExecutorInput[](
        1
      );
    newExecutors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1 days,
        executor: address(longExecutor)
      })
    });

    vm.expectRevert(bytes(Errors.EXECUTOR_ALREADY_SET_IN_DIFFERENT_LEVEL));
    payloadsController.updateExecutors(newExecutors);
  }

  function testUpdateExecutorWhenAlreadySetAsLevel1() public {
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory newExecutors = new IPayloadsControllerCore.UpdateExecutorInput[](
        1
      );
    newExecutors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1 days,
        executor: address(shortExecutor)
      })
    });

    vm.expectRevert(bytes(Errors.EXECUTOR_ALREADY_SET_IN_DIFFERENT_LEVEL));
    payloadsController.updateExecutors(newExecutors);
  }

  function testUpdateExecutorsWhenAccessLevel1() public {
    // new lvl 1 executor
    IExecutor newExecutor = new Executor();
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory newExecutors = new IPayloadsControllerCore.UpdateExecutorInput[](
        1
      );
    newExecutors[0] = IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1 days,
        executor: address(newExecutor)
      })
    });

    hoax(address(shortExecutor));

    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    payloadsController.updateExecutors(newExecutors);
  }

  function testUpdateGuardian() public {
    address newGuardian = address(1234567);

    hoax(GUARDIAN);
    vm.expectEmit(false, false, false, true);
    emit GuardianUpdated(GUARDIAN, newGuardian);

    IWithGuardian(address(payloadsController)).updateGuardian(newGuardian);

    assertEq(
      IWithGuardian(address(payloadsController)).guardian(),
      newGuardian
    );
  }

  // test payload flow methods
  function testCreatePayload(address target1, address target2) public {
    vm.assume(target1 != address(0) && target2 != address(0));
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](2);
    actions[0] = _getSimpleAction(target1);
    actions[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_2;
    actions[1] = _getSimpleAction(target2);

    vm.expectEmit(true, true, true, true);
    emit PayloadCreated(
      0,
      address(this),
      actions,
      PayloadsControllerUtils.AccessControl.Level_2
    );
    uint40 payloadId = payloadsController.createPayload(actions);

    IPayloadsControllerCore.Payload memory savedPayload = payloadsController
      .getPayloadById(payloadId);

    assertEq(savedPayload.creator, address(this));
    assertEq(
      uint8(savedPayload.maximumAccessLevelRequired),
      uint8(PayloadsControllerUtils.AccessControl.Level_2)
    );
    assertEq(savedPayload.createdAt, block.timestamp);
    assertEq(
      uint8(savedPayload.state),
      uint8(IPayloadsControllerCore.PayloadState.Created)
    );
    assertEq(savedPayload.queuedAt, 0);
    assertEq(savedPayload.executedAt, 0);
    assertEq(
      savedPayload.expirationTime,
      uint40(block.timestamp) + EXPIRATION_DELAY
    );

    assertEq(payloadsController.getPayloadsCount(), 1);
    assertEq(payloadId, payloadsController.getPayloadsCount() - 1);
  }

  function testCreatePayloadWithInvalidTarget() public {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = _getSimpleAction(address(0));

    vm.expectRevert(bytes(Errors.INVALID_ACTION_TARGET));
    payloadsController.createPayload(actions);
  }

  function testCreatePayloadWithInvalidAccessLevel(address target) public {
    vm.assume(target != address(0));
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = _getSimpleAction(target);
    actions[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_null;

    vm.expectRevert(bytes(Errors.INVALID_ACTION_ACCESS_LEVEL));
    payloadsController.createPayload(actions);
  }

  function testCreatePayloadWithoutActions() public {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](0);

    vm.expectRevert(bytes(Errors.INVALID_EMPTY_TARGETS));
    payloadsController.createPayload(actions);
  }

  function testCreatePayloadWithoutExecutorForMaxActionLvl(
    address target
  ) public {
    vm.assume(target != address(0));
    IPayloadsControllerCore newPayloadsController = _createPayloadsControllerLvl1();

    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](2);
    actions[0] = _getSimpleAction(target);
    actions[1] = _getSimpleAction(target);
    actions[1].accessLevel = PayloadsControllerUtils.AccessControl.Level_2;

    vm.expectRevert(
      bytes(Errors.EXECUTOR_WAS_NOT_SPECIFIED_FOR_REQUESTED_ACCESS_LEVEL)
    );
    newPayloadsController.createPayload(actions);
  }

  // -----------------------------------------------------------------------------

  function testQueuePayload() public {
    uint40 payloadId = _createPayloadWithLvl1_2();

    hoax(PAYLOAD_PORTAL);
    vm.expectEmit(false, false, false, true);
    emit PayloadQueued(payloadId);
    payloadsController.queue(
      payloadId,
      payloadsController.getPayloadById(payloadId).maximumAccessLevelRequired,
      uint40(block.timestamp + 10)
    );
    vm.clearMockedCalls();

    IPayloadsControllerCore.Payload memory savedPayload = payloadsController
      .getPayloadById(payloadId);

    assertEq(
      uint8(savedPayload.state),
      uint8(IPayloadsControllerCore.PayloadState.Queued)
    );
    assertEq(savedPayload.queuedAt, block.timestamp);
  }

  function testQueuePayloadWithBiggerAccessLevel() public {
    uint40 payloadId = _createPayloadWithLvl1();

    hoax(PAYLOAD_PORTAL);
    vm.expectEmit(false, false, false, true);
    emit PayloadQueued(payloadId);
    payloadsController.queue(
      payloadId,
      PayloadsControllerUtils.AccessControl.Level_2,
      uint40(block.timestamp + 10)
    );
    vm.clearMockedCalls();

    IPayloadsControllerCore.Payload memory savedPayload = payloadsController
      .getPayloadById(payloadId);

    assertEq(
      uint8(savedPayload.state),
      uint8(IPayloadsControllerCore.PayloadState.Queued)
    );
    assertEq(savedPayload.queuedAt, block.timestamp);
  }

  function testQueuePayloadWhenLowerAccessLevel() public {
    uint40 payloadId = _createPayloadWithLvl1_2();

    hoax(PAYLOAD_PORTAL);
    vm.expectRevert(bytes(Errors.INVALID_PROPOSAL_ACCESS_LEVEL));
    payloadsController.queue(
      payloadId,
      PayloadsControllerUtils.AccessControl.Level_1,
      uint40(block.timestamp + 10)
    );
    vm.clearMockedCalls();
  }

  function testQueuePayloadWithOlderProposalTimestamp() public {
    skip(10);
    uint40 payloadId = _createPayloadWithLvl1_2();

    uint40 proposalTimestamp = uint40(
      payloadsController.getPayloadById(payloadId).createdAt - 5
    );
    hoax(PAYLOAD_PORTAL);
    vm.expectRevert(bytes(Errors.PAYLOAD_NOT_CREATED_BEFORE_PROPOSAL));
    payloadsController.queue(
      payloadId,
      PayloadsControllerUtils.AccessControl.Level_2,
      proposalTimestamp
    );
    vm.clearMockedCalls();
  }

  function testQueueNonExistingPayload() public {
    uint40 payloadId = 2;

    hoax(PAYLOAD_PORTAL);
    vm.expectRevert(bytes(Errors.PAYLOAD_NOT_IN_CREATED_STATE));
    payloadsController.queue(
      payloadId,
      PayloadsControllerUtils.AccessControl.Level_1,
      uint40(block.timestamp + 10)
    );
  }

  function testQueuePayloadExpired() public {
    uint40 payloadId = _createPayloadWithLvl1_2();

    uint256 extraTime = 1234;

    IPayloadsControllerCore.Payload memory savedPayload = payloadsController
      .getPayloadById(payloadId);
    uint256 timestampToSkip = savedPayload.createdAt +
      payloadsController.EXPIRATION_DELAY() +
      extraTime;

    skip(timestampToSkip);

    vm.expectRevert(bytes(Errors.PAYLOAD_NOT_IN_CREATED_STATE));
    payloadsController.queue(
      payloadId,
      savedPayload.maximumAccessLevelRequired,
      uint40(block.timestamp + 10)
    );
  }

  // execute payload
  function testExecutePayload() public {
    uint40 payloadId = _createPayloadWithLvl1_2();
    _queuePayloadWithId(
      payloadId,
      payloadsController.getPayloadById(payloadId).maximumAccessLevelRequired,
      uint40(block.timestamp + 10)
    );

    IPayloadsControllerCore.Payload memory savedPayload;
    savedPayload = payloadsController.getPayloadById(payloadId);

    uint256 extraTime = 10;
    uint256 skipTimeToTimelock = savedPayload.queuedAt +
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_2
        )
        .delay +
      extraTime;
    skip(skipTimeToTimelock);

    payloadsController.executePayload(payloadId);

    savedPayload = payloadsController.getPayloadById(payloadId);

    assertEq(savedPayload.creator, address(this));
    assertEq(
      uint8(savedPayload.maximumAccessLevelRequired),
      uint8(PayloadsControllerUtils.AccessControl.Level_2)
    );

    assertEq(savedPayload.createdAt, 1);
    assertEq(
      uint8(savedPayload.state),
      uint8(IPayloadsControllerCore.PayloadState.Executed)
    );
    assertEq(savedPayload.queuedAt, 1);
    assertEq(savedPayload.executedAt, skipTimeToTimelock + 1);

    assertEq(payloadsController.getPayloadsCount(), 1);
    assertEq(payloadId, payloadsController.getPayloadsCount() - 1);
  }

  function testExecutePayloadNotExists() public {
    vm.expectRevert(bytes(Errors.PAYLOAD_NOT_IN_QUEUED_STATE));
    payloadsController.executePayload(3);
  }

  function testExecutePayloadNotQueued() public {
    uint40 payloadId = _createPayloadWithLvl1_2();

    vm.expectRevert(bytes(Errors.PAYLOAD_NOT_IN_QUEUED_STATE));
    payloadsController.executePayload(payloadId);
  }

  function testExecutePayloadInTimelock() public {
    uint40 payloadId = _createPayloadWithLvl1_2();
    _queuePayloadWithId(
      payloadId,
      payloadsController.getPayloadById(payloadId).maximumAccessLevelRequired,
      uint40(block.timestamp + 10)
    );

    IPayloadsControllerCore.Payload memory savedPayload;
    savedPayload = payloadsController.getPayloadById(payloadId);

    uint256 extraTime = 1000;
    uint256 skipTimeToTimelock = savedPayload.queuedAt +
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_2
        )
        .delay -
      extraTime;
    skip(skipTimeToTimelock);

    vm.expectRevert(bytes(Errors.TIMELOCK_NOT_FINISHED));
    payloadsController.executePayload(payloadId);
  }

  function testExecutePayloadAfterGracePeriod() public {
    uint40 payloadId = _createPayloadWithLvl1_2();
    _queuePayloadWithId(
      payloadId,
      payloadsController.getPayloadById(payloadId).maximumAccessLevelRequired,
      uint40(block.timestamp + 10)
    );

    IPayloadsControllerCore.Payload memory savedPayload;
    savedPayload = payloadsController.getPayloadById(payloadId);

    uint256 extraTime = 10;
    uint256 skipTimeToTimelock = savedPayload.queuedAt +
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_2
        )
        .delay +
      savedPayload.gracePeriod +
      extraTime;
    skip(skipTimeToTimelock);

    vm.expectRevert(bytes(Errors.PAYLOAD_NOT_IN_QUEUED_STATE));
    payloadsController.executePayload(payloadId);
  }

  // cancel payload
  function testCancelPayloadWhenCreated() public {
    uint40 payloadId = _createPayloadWithLvl1_2();

    IPayloadsControllerCore.Payload memory prevPayload = payloadsController
      .getPayloadById(payloadId);

    hoax(GUARDIAN);

    vm.expectEmit(false, false, false, true);
    emit PayloadCancelled(payloadId);
    payloadsController.cancelPayload(payloadId);

    IPayloadsControllerCore.Payload memory savedPayload = payloadsController
      .getPayloadById(payloadId);

    assertEq(
      uint8(savedPayload.state),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
    assertEq(savedPayload.cancelledAt, block.timestamp);
    assertEq(savedPayload.creator, prevPayload.creator);
    assertEq(
      uint8(savedPayload.maximumAccessLevelRequired),
      uint8(prevPayload.maximumAccessLevelRequired)
    );
    assertEq(savedPayload.createdAt, prevPayload.createdAt);
    assertEq(savedPayload.queuedAt, prevPayload.queuedAt);
    assertEq(savedPayload.executedAt, prevPayload.executedAt);

    assertEq(payloadsController.getPayloadsCount(), 1);
    assertEq(payloadId, payloadsController.getPayloadsCount() - 1);
  }

  function testCancelPayloadWhenQueued() public {
    uint40 payloadId = _createPayloadWithLvl1_2();
    _queuePayloadWithId(
      payloadId,
      payloadsController.getPayloadById(payloadId).maximumAccessLevelRequired,
      uint40(block.timestamp + 10)
    );

    IPayloadsControllerCore.Payload memory prevPayload = payloadsController
      .getPayloadById(payloadId);

    hoax(GUARDIAN);

    vm.expectEmit(false, false, false, true);
    emit PayloadCancelled(payloadId);
    payloadsController.cancelPayload(payloadId);

    IPayloadsControllerCore.Payload memory savedPayload = payloadsController
      .getPayloadById(payloadId);

    assertEq(
      uint8(savedPayload.state),
      uint8(IPayloadsControllerCore.PayloadState.Cancelled)
    );
    assertEq(savedPayload.cancelledAt, block.timestamp);
    assertEq(savedPayload.creator, prevPayload.creator);
    assertEq(
      uint8(savedPayload.maximumAccessLevelRequired),
      uint8(prevPayload.maximumAccessLevelRequired)
    );
    assertEq(savedPayload.createdAt, prevPayload.createdAt);
    assertEq(savedPayload.queuedAt, prevPayload.queuedAt);
    assertEq(savedPayload.executedAt, prevPayload.executedAt);

    assertEq(payloadsController.getPayloadsCount(), 1);
    assertEq(payloadId, payloadsController.getPayloadsCount() - 1);
  }

  function testCancelPayloadWhenExecuted() public {
    uint40 payloadId = _createPayloadWithLvl1_2();
    _queuePayloadWithId(
      payloadId,
      payloadsController.getPayloadById(payloadId).maximumAccessLevelRequired,
      uint40(block.timestamp + 10)
    );
    _executePayloadLvl2(payloadId);

    hoax(GUARDIAN);

    vm.expectRevert(bytes(Errors.PAYLOAD_NOT_IN_THE_CORRECT_STATE));
    payloadsController.cancelPayload(payloadId);
  }

  function testCancelPayloadWhenNotExist() public {
    hoax(GUARDIAN);

    vm.expectRevert(bytes(Errors.PAYLOAD_NOT_IN_THE_CORRECT_STATE));
    payloadsController.cancelPayload(3);
  }

  function testCancelPayloadWhenNotGuardian() public {
    uint40 payloadId = _createPayloadWithLvl1_2();
    _queuePayloadWithId(
      payloadId,
      payloadsController.getPayloadById(payloadId).maximumAccessLevelRequired,
      uint40(block.timestamp + 10)
    );

    vm.expectRevert(bytes('ONLY_BY_GUARDIAN'));
    payloadsController.cancelPayload(payloadId);
  }

  function testExpirationDelayCanNotBe0() public view {
    assert(payloadsController.EXPIRATION_DELAY() != 0);
  }

  // helpers
  function _createPayloadsControllerLvl1()
    internal
    returns (IPayloadsControllerCore)
  {
    // create payloads controller without lvl 2

    IExecutor newExecutor = new Executor();

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory newExecutors = new IPayloadsControllerCore.UpdateExecutorInput[](
        1
      );
    executor3.executorConfig.executor = address(newExecutor);

    newExecutors[0] = executor3;

    address newPayloadsControllerProxy = proxyFactory.create(
      address(payloadsControllerImpl),
      ProxyAdmin(ADMIN),
      abi.encodeWithSelector(
        payloadsControllerImpl.initialize.selector,
        address(this),
        GUARDIAN,
        newExecutors
      )
    );

    return PayloadsControllerMock(payable(newPayloadsControllerProxy));
  }

  function _createPayloadWithLvl1_2() internal returns (uint40) {
    address payload = address(new PayloadTest());

    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](2);
    actions[0] = _getSimpleAction(payload);
    actions[1] = _getSimpleAction(payload);
    actions[1].accessLevel = PayloadsControllerUtils.AccessControl.Level_2;

    return payloadsController.createPayload(actions);
  }

  function _createPayloadWithLvl1() internal returns (uint40) {
    address payload = address(new PayloadTest());

    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = _getSimpleAction(payload);

    return payloadsController.createPayload(actions);
  }

  function _queuePayloadWithId(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel,
    uint40 proposalVoteActivationTimestamp
  ) internal {
    hoax(PAYLOAD_PORTAL);
    payloadsController.queue(
      payloadId,
      accessLevel,
      proposalVoteActivationTimestamp
    );
  }

  function _executePayloadLvl2(uint40 payloadId) internal {
    IPayloadsControllerCore.Payload memory savedPayload;
    savedPayload = payloadsController.getPayloadById(payloadId);

    uint256 extraTime = 10;
    uint256 skipTimeToTimelock = savedPayload.queuedAt +
      payloadsController
        .getExecutorSettingsByAccessControl(
          PayloadsControllerUtils.AccessControl.Level_2
        )
        .delay +
      extraTime;
    skip(skipTimeToTimelock);

    payloadsController.executePayload(payloadId);
  }
}
