// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPayloadsControllerCore} from '../../src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';
import {IPermissionedPayloadsController, PermissionedPayloadsController} from '../../src/contracts/payloads/PermissionedPayloadsController.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
import {Executor, IExecutor, Ownable} from '../../src/contracts/payloads/Executor.sol';
import {PayloadTest} from './utils/PayloadTest.sol';
import {Test} from 'forge-std/Test.sol';

contract PermissionedPayloadsControllerTest is Test {
  IPermissionedPayloadsController permissionedPayloadPortal;

  IExecutor internal executor;

  modifier initializeTest(
    address admin,
    address guardian,
    address payloadsManager,
    address origin
  ) {
    vm.startPrank(origin);

    executor = new Executor();
    TransparentProxyFactory proxyFactory = new TransparentProxyFactory();

    permissionedPayloadPortal = new PermissionedPayloadsController();

    IPayloadsControllerCore.UpdateExecutorInput memory executorInput = IPayloadsControllerCore
        .UpdateExecutorInput({
          accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
          executorConfig: IPayloadsControllerCore.ExecutorConfig({
            delay: 1 days,
            executor: address(0)
          })
        });

    executorInput.executorConfig.executor = address(executor);
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = executorInput;

    permissionedPayloadPortal = IPermissionedPayloadsController(
      proxyFactory.create(
        address(permissionedPayloadPortal),
        admin,
        abi.encodeWithSelector(
          IPermissionedPayloadsController.initialize.selector,
          address(this),
          guardian,
          payloadsManager,
          executors
        )
      )
    );

    Ownable(address(executor)).transferOwnership(
      address(permissionedPayloadPortal)
    );
    _;
    vm.stopPrank();
  }

  event SimpleExecute(string);

  function testGetPayloadsManager(
    address admin,
    address guardian,
    address payloadsManager,
    address origin
  ) external initializeTest(admin, guardian, payloadsManager, origin) {
    assertEq(permissionedPayloadPortal.payloadsManager(), payloadsManager);
  }

  function testPayloadsCreationWithInvalidCaller(
    address admin,
    address guardian,
    address payloadsManager,
    address origin,
    address user
  ) external initializeTest(admin, guardian, payloadsManager, origin) {
    vm.assume(user != payloadsManager);
    vm.assume(user != admin);
    vm.expectRevert(bytes(Errors.ONLY_BY_PAYLOADS_MANAGER));
    _createPayload(user);
  }

  function testPayloadsCreation(
    address admin,
    address guardian,
    address payloadsManager,
    address origin
  ) external initializeTest(admin, guardian, payloadsManager, origin) {
    _createPayload(payloadsManager);
  }

  function testPayloadTimeLockNotExceeded(
    address admin,
    address guardian,
    address payloadsManager,
    address origin,
    uint256 warpTime
  ) external initializeTest(admin, guardian, payloadsManager, origin) {
    uint40 payloadId = _createPayload(payloadsManager);

    uint256 invalidWarpTime = warpTime % 1 days;
    vm.warp(invalidWarpTime);
    vm.expectRevert(bytes(Errors.TIMELOCK_NOT_FINISHED));
    permissionedPayloadPortal.executePayload(payloadId);
  }

  function testPayloadExecution(
    address admin,
    address guardian,
    address payloadsManager,
    address origin
  ) external initializeTest(admin, guardian, payloadsManager, origin) {
    // create and queue payload
    PayloadTest helper = new PayloadTest();
    uint40 payloadId = _createPayload(payloadsManager, address(helper));

    // solium-disable-next-line
    vm.warp(block.timestamp + 1 days + 1);
    vm.expectEmit(false, false, false, false);
    emit SimpleExecute('simple');
    permissionedPayloadPortal.executePayload(payloadId);
  }

  function testPayloadCancellationWithInvalidCaller(
    address admin,
    address guardian,
    address payloadsManager,
    address origin,
    address user
  ) external initializeTest(admin, guardian, payloadsManager, origin) {
    vm.assume(user != payloadsManager);
    vm.assume(user != guardian);
    vm.assume(user != admin);
    uint40 payloadId = _createPayload(payloadsManager);
    vm.expectRevert(bytes(Errors.ONLY_BY_PAYLOADS_MANAGER_OR_GUARDIAN));
    permissionedPayloadPortal.cancelPayload(payloadId);
  }

  function testPayloadCancellationWithGuardian(
    address admin,
    address guardian,
    address payloadsManager,
    address origin
  ) external initializeTest(admin, guardian, payloadsManager, origin) {
    uint40 payloadId = _createPayload(payloadsManager);
    vm.startPrank(guardian);
    permissionedPayloadPortal.cancelPayload(payloadId);
    vm.stopPrank();
  }

  function testPayloadCancellationWithPayloadsManager(
    address admin,
    address guardian,
    address payloadsManager,
    address origin
  ) external initializeTest(admin, guardian, payloadsManager, origin) {
    uint40 payloadId = _createPayload(payloadsManager);
    vm.startPrank(payloadsManager);
    permissionedPayloadPortal.cancelPayload(payloadId);
    vm.stopPrank();
  }

  function _createPayload(address caller) internal returns (uint40) {
    return _createPayload(caller, address(123));
  }

  function _createPayload(address caller, address target) internal returns (uint40) {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0].target = target;
    actions[0].value = 0;
    actions[0].signature = 'execute()';
    actions[0].callData = bytes('');
    actions[0].withDelegateCall = true;
    actions[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_1;

    vm.startPrank(caller);
    uint40 payloadId = permissionedPayloadPortal.createPayload(actions);
    vm.stopPrank();
    return payloadId;
  }
}
