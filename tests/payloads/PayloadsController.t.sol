// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import 'forge-std/Test.sol';
import {PayloadsController, BridgingHelper} from '../../src/contracts/payloads/PayloadsController.sol';
import {IPayloadsController} from '../../src/contracts/payloads/interfaces/IPayloadsController.sol';
import {IPayloadsControllerCore} from '../../src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';

contract PayloadsControllerTest is Test {
  address constant ADMIN = address(123);
  address constant GUARDIAN = address(1234);
  address public constant MESSAGE_ORIGINATOR = address(1234190812);
  address public constant CROSS_CHAIN_CONTROLLER = address(123456);

  uint256 public constant ORIGIN_CHAIN_ID = 1;

  IPayloadsController public payloadPortal;
  TransparentProxyFactory public proxyFactory;

  IPayloadsControllerCore.UpdateExecutorInput executor1 =
    IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: uint40(86400),
        executor: address(81201287423)
      })
    });

  event MessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bool indexed delivered,
    BridgingHelper.MessageType messageType,
    bytes message,
    bytes reason
  );
  event IncorrectTypeMessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bytes message,
    bytes reason
  );

  function setUp() public {
    proxyFactory = new TransparentProxyFactory();

    PayloadsController payloadPortalImpl = new PayloadsController(
      CROSS_CHAIN_CONTROLLER,
      MESSAGE_ORIGINATOR,
      ORIGIN_CHAIN_ID
    );

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = executor1;

    payloadPortal = IPayloadsController(
      proxyFactory.create(
        address(payloadPortalImpl),
        ADMIN,
        abi.encodeWithSelector(
          IPayloadsControllerCore.initialize.selector,
          address(this),
          GUARDIAN,
          executors
        )
      )
    );
  }

  function testGetCrossChainController() public {
    assertEq(payloadPortal.CROSS_CHAIN_CONTROLLER(), CROSS_CHAIN_CONTROLLER);
  }

  function testGetMessageOriginator() public {
    assertEq(payloadPortal.MESSAGE_ORIGINATOR(), MESSAGE_ORIGINATOR);
  }

  function testGetOriginChainId() public {
    assertEq(uint8(payloadPortal.ORIGIN_CHAIN_ID()), uint8(ORIGIN_CHAIN_ID));
  }

  function testCreatePayloadsControllerWithInvalidCCC() public {
    vm.expectRevert(bytes(Errors.INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS));
    new PayloadsController(address(0), MESSAGE_ORIGINATOR, ORIGIN_CHAIN_ID);
  }

  function testCreatePayloadsControllerWithInvalidMessageOriginator() public {
    vm.expectRevert(bytes(Errors.INVALID_MESSAGE_ORIGINATOR_ADDRESS));
    new PayloadsController(CROSS_CHAIN_CONTROLLER, address(0), ORIGIN_CHAIN_ID);
  }

  function testCreatePayloadsControllerWithInvalidOriginChain() public {
    vm.expectRevert(bytes(Errors.INVALID_ORIGIN_CHAIN_ID));
    new PayloadsController(CROSS_CHAIN_CONTROLLER, MESSAGE_ORIGINATOR, 0);
  }

  function testReceiveCrossChainMessage() public {
    uint40 payloadId = _createPayload();
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        chain: ORIGIN_CHAIN_ID,
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        payloadsController: address(102358),
        payloadId: payloadId
      });
    uint40 timestamp = uint40(block.timestamp + 10);
    bytes memory message = abi.encode(
      payloadId,
      PayloadsControllerUtils.AccessControl.Level_1,
      timestamp
    );
    bytes memory messageWithType = BridgingHelper.encodePayloadExecutionMessage(
      payload,
      timestamp
    );

    hoax(CROSS_CHAIN_CONTROLLER);
    bytes memory empty;
    vm.expectEmit(true, true, true, true);
    emit MessageReceived(
      MESSAGE_ORIGINATOR,
      ORIGIN_CHAIN_ID,
      true,
      BridgingHelper.MessageType.Payload_Execution,
      message,
      empty
    );
    payloadPortal.receiveCrossChainMessage(
      MESSAGE_ORIGINATOR,
      ORIGIN_CHAIN_ID,
      messageWithType
    );
  }

  function testReceiveCrossChainMessageWhenIncorrectMessage() public {
    uint40 payloadId = _createPayload();
    bytes memory message = abi.encode(payloadId);

    hoax(CROSS_CHAIN_CONTROLLER);
    bytes memory empty;
    vm.expectEmit(true, true, true, true);
    emit IncorrectTypeMessageReceived(
      MESSAGE_ORIGINATOR,
      ORIGIN_CHAIN_ID,
      message,
      empty
    );
    payloadPortal.receiveCrossChainMessage(
      MESSAGE_ORIGINATOR,
      ORIGIN_CHAIN_ID,
      message
    );
  }

  function testReceiveCrossChainMessageWhenIncorrectOriginator() public {
    bytes memory message = abi.encode();

    hoax(CROSS_CHAIN_CONTROLLER);
    vm.expectRevert(bytes(Errors.WRONG_MESSAGE_ORIGIN));
    payloadPortal.receiveCrossChainMessage(
      address(1),
      ORIGIN_CHAIN_ID,
      message
    );
  }

  function testReceiveCrossChainMessageWhenIncorrectChainId() public {
    bytes memory message = abi.encode();
    hoax(CROSS_CHAIN_CONTROLLER);
    vm.expectRevert(bytes(Errors.WRONG_MESSAGE_ORIGIN));
    payloadPortal.receiveCrossChainMessage(MESSAGE_ORIGINATOR, 43114, message);
  }

  function testReceiveCrossChainMessageWhenIncorrectCaller() public {
    bytes memory message = abi.encode();
    vm.expectRevert(bytes(Errors.WRONG_MESSAGE_ORIGIN));
    payloadPortal.receiveCrossChainMessage(
      MESSAGE_ORIGINATOR,
      ORIGIN_CHAIN_ID,
      message
    );
  }

  function _createPayload() internal returns (uint40) {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0].target = address(1239707);
    actions[0].value = 0;
    actions[0].signature = 'execute()';
    actions[0].callData = bytes('');
    actions[0].withDelegateCall = true;
    actions[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_1;

    return payloadPortal.createPayload(actions);
  }
}
