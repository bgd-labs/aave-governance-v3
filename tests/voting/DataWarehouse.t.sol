// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {DataWarehouse} from '../../src/contracts/voting/DataWarehouse.sol';
import {IDataWarehouse} from '../../src/contracts/voting/interfaces/IDataWarehouse.sol';
import {StateProofVerifier} from '../../src/contracts/voting/libs/StateProofVerifier.sol';
import {SlotUtils} from '../../src/contracts/libraries/SlotUtils.sol';
import {BaseProofTest} from '../utils/BaseProofTest.sol';

contract DataWarehouseTest is BaseProofTest {
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
    dataWarehouse = new DataWarehouse();

    // we init voting strategy so we can access supported token addresses
    _initVotingStrategy();
    _getRootsAndProofs();
    _;
  }

  function setUp() public {}

  function testProcessData() public initializeProofs {
    vm.expectEmit(true, true, true, true);
    emit StorageRootProcessed(address(this), AAVE, proofBlockHash);
    dataWarehouse.processStorageRoot(
      AAVE,
      proofBlockHash,
      aaveProofs.blockHeaderRLP,
      aaveProofs.accountStateProofRLP
    );

    bytes32 storageRoots = dataWarehouse.getStorageRoots(AAVE, proofBlockHash);
    bool result = storageRoots != bytes32(0);
    assertEq(result, true);
  }

  function testRegisterExchangeRate() public initializeProofs {
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
      stkAaveProofs.stkAaveExchangeRateStorageProofRlp
    );

    uint256 exchangeRateValue = dataWarehouse.getRegisteredSlot(
      proofBlockHash,
      STK_AAVE,
      stkAaveProofs.stkAaveExchangeRateSlot
    );
    uint256 exchangeRate = uint256(uint216(exchangeRateValue));
    emit log_uint(exchangeRate);
    assertEq(exchangeRate, stkAaveProofs.exchangeRate);
  }

  function testGetStorage() public initializeProofs {
    dataWarehouse.processStorageRoot(
      AAVE,
      proofBlockHash,
      aaveProofs.blockHeaderRLP,
      aaveProofs.accountStateProofRLP
    );

    StateProofVerifier.SlotValue memory storageInfo = dataWarehouse.getStorage(
      AAVE,
      proofBlockHash,
      SlotUtils.getAccountSlotHash(proofVoter, aaveProofs.baseBalanceSlotRaw),
      aaveProofs.balanceStorageProofRlp
    );

    assertEq(storageInfo.exists, true);
    assertEq(storageInfo.value, aaveProofs.balanceSlotValue);
  }

  // SLOT
  function testGetAccountBalanceSlotHash() public initializeProofs {
    address holder = address(81967235);
    uint256 balanceMappingPosition = 0;

    bytes32 slot = keccak256(
      abi.encodePacked(
        bytes32(uint256(uint160(holder))),
        balanceMappingPosition
      )
    );

    bytes32 calculatedSlot = SlotUtils.getAccountSlotHash(
      holder,
      balanceMappingPosition
    );

    assertEq(slot, calculatedSlot);
  }
}
