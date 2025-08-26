// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {DataWarehouse} from '../../src/contracts/voting/DataWarehouse.sol';
import {IDataWarehouse} from '../../src/contracts/voting/interfaces/IDataWarehouse.sol';
import {StateProofVerifier} from '../../src/contracts/voting/libs/StateProofVerifier.sol';
import {SlotUtils} from '../../src/contracts/libraries/SlotUtils.sol';
import {BaseProofTest} from '../utils/BaseProofTest.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';

contract DataWarehouseTestIntegration is BaseProofTest {
  event StorageRootProcessed(
    address indexed caller,
    address indexed account,
    bytes32 indexed blockHash
  );

  event StorageSlotProcessed(
    address indexed caller,
    address indexed account,
    bytes32 indexed blockHash,
    bytes32 slot,
    uint256 value
  );

  modifier initializeProofs() {    
    // we init voting strategy so we can access supported token addresses
    _initVotingStrategy();
    _getRootsAndProofs();
    _;
  }

  modifier initializeDataWarehouseFromFork() {
    dataWarehouse = DataWarehouse(0x1699FE9CaDC8a0b6c93E06B62Ab4592a0fFEcF61);
    _;
  }

  function setUp() public {
    vm.createSelectFork('ethereum', 22060440);
  }

  // Test that when processing truncated proofs we get storage roots as 0, and when we try to get
  // registered slot value we get 0. (With current implementation)
  // but when deploying new implementation we can not process truncated proofs.
  function testProcessData() public initializeDataWarehouseFromFork initializeProofs {
    vm.expectEmit(true, true, true, true);
    emit StorageRootProcessed(address(this), AAVE, proofBlockHash);
    dataWarehouse.processStorageRoot(
      AAVE,
      proofBlockHash,
      aaveProofs.blockHeaderRLP,
      aaveProofs.accountStateProofRLPTruncated
    );

    bytes32 storageRoots = dataWarehouse.getStorageRoots(AAVE, proofBlockHash);
    bool result = storageRoots == bytes32(0);
    assertEq(result, true);

    uint256 registeredSlot = dataWarehouse.getRegisteredSlot(
      proofBlockHash,
      AAVE,
      SlotUtils.getAccountSlotHash(proofVoter, aaveProofs.baseBalanceSlotRaw)
    );

    assertEq(registeredSlot, 0);

    dataWarehouse = new DataWarehouse();
    vm.expectRevert();
    dataWarehouse.processStorageRoot(
      AAVE,
      proofBlockHash,
      aaveProofs.blockHeaderRLP,
      aaveProofs.accountStateProofRLPTruncated
    );
  }

  // Test that when processing truncated proofs for the storage slot, we get 0 as registered slot value.
  // But when deploying new implementation we can not process truncated proofs.
  function testProcessStorageSlot() public initializeDataWarehouseFromFork initializeProofs {
    vm.expectEmit(true, true, true, true);
    emit StorageRootProcessed(address(this), STK_AAVE, proofBlockHash);
    dataWarehouse.processStorageRoot(
      STK_AAVE,
      proofBlockHash,
      stkAaveProofs.blockHeaderRLP,
      stkAaveProofs.accountStateProofRLP
    );

    vm.expectEmit(true, true, true, false);
    emit StorageSlotProcessed(
      address(this),
      STK_AAVE,
      proofBlockHash,
      stkAaveProofs.stkAaveExchangeRateSlot,
      1
    );
    dataWarehouse.processStorageSlot(
      STK_AAVE,
      proofBlockHash,
      stkAaveProofs.stkAaveExchangeRateSlot,
      stkAaveProofs.stkAaveExchangeRateStorageProofRlpTruncated
    );

    uint256 exchangeRateValue = dataWarehouse.getRegisteredSlot(
      proofBlockHash,
      STK_AAVE,
      stkAaveProofs.stkAaveExchangeRateSlot
    );
    uint256 exchangeRate = uint256(uint216(exchangeRateValue));
    assertEq(exchangeRate, 0);

    dataWarehouse = new DataWarehouse();
    vm.expectRevert();
    dataWarehouse.processStorageRoot(
      STK_AAVE,
      proofBlockHash,
      stkAaveProofs.blockHeaderRLP,
      stkAaveProofs.accountStateProofRLPTruncated
    );
    vm.expectRevert(bytes(Errors.UNPROCESSED_STORAGE_ROOT));
    dataWarehouse.processStorageSlot(
      STK_AAVE,
      proofBlockHash,
      stkAaveProofs.stkAaveExchangeRateSlot,
      stkAaveProofs.stkAaveExchangeRateStorageProofRlp
    );
  }
}