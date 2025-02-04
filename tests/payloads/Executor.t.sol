// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';
import {PayloadTest} from './utils/PayloadTest.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';

contract ExecutorTest is Test {
  address public constant TARGET = address(65536+12345);
  uint256 public constant VALUE = 0;
  string public constant SIGNATURE = 'execute()';
  bytes public constant DATA = bytes('');
  bool public constant WITH_DELEGATE_CALL = true;

  Executor public executor;
  PayloadTest public payloadTest;

  event ComplexExecute(string, uint256);

  event ExecutedAction(
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall,
    bytes resultData
  );

  function setUp() public {
    executor = new Executor();
    payloadTest = new PayloadTest();
  }

  function testExecuteTransaction() public {
    uint256 executionTime = block.timestamp;

    vm.expectEmit(true, false, false, true);
    emit ExecutedAction(
      TARGET,
      VALUE,
      SIGNATURE,
      DATA,
      executionTime,
      WITH_DELEGATE_CALL,
      bytes('')
    );

    executor.executeTransaction(
      TARGET,
      VALUE,
      SIGNATURE,
      DATA,
      WITH_DELEGATE_CALL
    );
  }

  function testExecuteTransactionWhenInvalidTarget() public {
    vm.expectRevert(bytes(Errors.INVALID_EXECUTION_TARGET));
    executor.executeTransaction(
      address(0),
      VALUE,
      SIGNATURE,
      DATA,
      WITH_DELEGATE_CALL
    );
  }

  function testExecuteTransactionWithDelegateAndValue() public {
    uint256 executionTime = block.timestamp;
    uint256 value = 1 ether;

    vm.expectEmit(true, false, false, true);
    emit ExecutedAction(
      TARGET,
      value,
      SIGNATURE,
      DATA,
      executionTime,
      WITH_DELEGATE_CALL,
      bytes('')
    );
    deal(address(this), 10 ether);
    executor.executeTransaction{value: 1 ether}(
      TARGET,
      value,
      SIGNATURE,
      DATA,
      WITH_DELEGATE_CALL
    );
  }

  function testExecuteTransactionWithDelegateAndNotEnoughValue() public {
    vm.expectRevert(bytes(Errors.NOT_ENOUGH_MSG_VALUE));
    deal(address(this), 10 ether);
    executor.executeTransaction{value: 1 ether}(
      TARGET,
      2 ether,
      SIGNATURE,
      DATA,
      WITH_DELEGATE_CALL
    );
  }

  function testExecuteTransactionWithoutDelegateCall() public {
    uint256 executionTime = block.timestamp;
    string memory signature = 'complexExecute(uint256)';
    bool withDelegateCall = false;
    address target = address(payloadTest);
    bytes memory data = abi.encodePacked(uint256(10));

    vm.expectEmit(true, false, false, true);
    emit ComplexExecute('complex', 10);
    vm.expectEmit(true, false, false, true);
    emit ExecutedAction(
      target,
      VALUE,
      signature,
      data,
      executionTime,
      withDelegateCall,
      bytes('')
    );

    executor.executeTransaction(
      target,
      VALUE,
      signature,
      data,
      withDelegateCall
    );
  }

  function testExecuteTransactionWithoutSignature() public {
    uint256 executionTime = block.timestamp;
    string memory signature = '';
    bool withDelegateCall = true;
    address target = address(payloadTest);
    bytes memory data = abi.encodePacked(
      bytes4(keccak256(bytes('complexExecute(uint256)'))),
      uint256(10)
    );

    vm.expectEmit(true, false, false, true);
    emit ComplexExecute('complex', 10);
    vm.expectEmit(true, false, false, true);
    emit ExecutedAction(
      target,
      VALUE,
      signature,
      data,
      executionTime,
      withDelegateCall,
      bytes('')
    );

    executor.executeTransaction(
      target,
      VALUE,
      signature,
      data,
      withDelegateCall
    );
  }

  function testExecuteTransactionFails() public {
    string memory signature = 'complexExecute()';
    bool withDelegateCall = false;
    address target = address(payloadTest);
    bytes memory data = abi.encodePacked(uint256(10));

    vm.expectRevert(bytes(Errors.FAILED_ACTION_EXECUTION));
    executor.executeTransaction(
      target,
      VALUE,
      signature,
      data,
      withDelegateCall
    );
  }

  function testExecuteTransactionWhenNotOwner(address randomOwner) public {
    vm.assume(randomOwner != address(this));
    hoax(randomOwner);

    vm.expectRevert(bytes(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, randomOwner)));
    executor.executeTransaction(
      TARGET,
      VALUE,
      SIGNATURE,
      DATA,
      WITH_DELEGATE_CALL
    );
  }
}
