// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPayloadsControllerCore} from '../../src/contracts/payloads/interfaces/IPayloadsControllerCore.sol';
import {IPermissionedPayloadsController, PermissionedPayloadsController} from '../../src/contracts/payloads/PermissionedPayloadsController.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
import {Executor, IExecutor, Ownable} from '../../src/contracts/payloads/Executor.sol';
import {PayloadTest} from "./utils/PayloadTest.sol";
import {Test} from "forge-std/Test.sol";

contract PermissionedPayloadsControllerTest is Test {
  address constant ADMIN = address(123);
  address constant GUARDIAN = address(1234);
  address public constant PAYLOAD_MANAGER = address(184823);

  IPermissionedPayloadsController permissionedPayloadPortal;

  IExecutor internal executor;
  IPayloadsControllerCore.UpdateExecutorInput executorInput =
    IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: 1 days,
        executor: address(0)
      })
    });

  event SimpleExecute(string);

  function setUp() external {
    executor = new Executor();
    TransparentProxyFactory proxyFactory = new TransparentProxyFactory();

    permissionedPayloadPortal = new PermissionedPayloadsController();

    executorInput.executorConfig.executor = address(executor);
    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = executorInput;

    permissionedPayloadPortal = IPermissionedPayloadsController(
      proxyFactory.create(
        address(permissionedPayloadPortal),
        ADMIN,
        abi.encodeWithSelector(
          IPermissionedPayloadsController.initialize.selector,
          address(this),
          GUARDIAN,
          PAYLOAD_MANAGER,
          executors
        )
      )
    );

    Ownable(address(executor)).transferOwnership(address(permissionedPayloadPortal));
  }

  function testGetPayloadsManager() external {
    assertEq(permissionedPayloadPortal.payloadsManager(), PAYLOAD_MANAGER);
  }

  function testPayloadsCreationWithInvalidCaller() external {
    vm.expectRevert("ONLY_BY_PAYLOAD_MANAGER");
    _createPayload();
  }

  function testPayloadsCreation() external {
    hoax(PAYLOAD_MANAGER);
    _createPayload();
  }

  function testPayloadQueuingWithInvalidCaller() external {
    hoax(PAYLOAD_MANAGER);
    uint40 payloadId = _createPayload();

    vm.expectRevert("ONLY_BY_PAYLOAD_MANAGER");
    permissionedPayloadPortal.queuePayload(payloadId, PayloadsControllerUtils.AccessControl.Level_1);
  }

  function testPayloadQueuing() external {
    vm.startPrank(PAYLOAD_MANAGER);
    uint40 payloadId = _createPayload();

    permissionedPayloadPortal.queuePayload(payloadId, PayloadsControllerUtils.AccessControl.Level_1);
  }

  function testPayloadTimeLockNotExceeded() external {
    vm.startPrank(PAYLOAD_MANAGER);
    uint40 payloadId = _createPayload();
    permissionedPayloadPortal.queuePayload(payloadId, PayloadsControllerUtils.AccessControl.Level_1);

    vm.expectRevert(bytes(Errors.TIMELOCK_NOT_FINISHED));
    permissionedPayloadPortal.executePayload(payloadId);
  }

  function testPayloadExecution() external {
    // create and queue payload
    PayloadTest helper = new PayloadTest();
    vm.startPrank(PAYLOAD_MANAGER);
    uint40 payloadId = _createPayload(address(helper));
    permissionedPayloadPortal.queuePayload(payloadId, PayloadsControllerUtils.AccessControl.Level_1);
    vm.stopPrank();

    // solium-disable-next-line
    vm.warp(block.timestamp + 1 days + 1);
    vm.expectEmit(false, false, false, false);
    emit SimpleExecute("simple");
    permissionedPayloadPortal.executePayload(payloadId);
  }

  function testPayloadCancellationWithInvalidCaller() external {
    vm.prank(PAYLOAD_MANAGER);
    uint40 payloadId = _createPayload();
    vm.expectRevert("ONLY_BY_PAYLOAD_MANAGER_OR_GUARDIAN");
    permissionedPayloadPortal.cancelPayload(payloadId);
  }

  function testPayloadCancellationWithGuardian() external {
    vm.prank(PAYLOAD_MANAGER);
    uint40 payloadId = _createPayload();
    vm.prank(GUARDIAN);
    permissionedPayloadPortal.cancelPayload(payloadId);
  }

  function testPayloadCancellationWithPayloadsManager() external {
    vm.prank(PAYLOAD_MANAGER);
    uint40 payloadId = _createPayload();
    vm.prank(PAYLOAD_MANAGER);
    permissionedPayloadPortal.cancelPayload(payloadId);
  }


  function _createPayload() internal returns (uint40) {
    return _createPayload(address(123));
  }

  function _createPayload(address target) internal returns (uint40) {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0].target = target;
    actions[0].value = 0;
    actions[0].signature = 'execute()';
    actions[0].callData = bytes('');
    actions[0].withDelegateCall = true;
    actions[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_1;

    return permissionedPayloadPortal.createPayload(actions);
  }
}
