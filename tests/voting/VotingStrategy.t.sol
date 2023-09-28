// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {VotingStrategy, IVotingStrategy, IBaseVotingStrategy} from '../../src/contracts/voting/VotingStrategy.sol';
import {IDataWarehouse} from '../../src/contracts/voting/DataWarehouse.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
import {BaseProofTest, VotingStrategyTest as VSTest} from '../utils/BaseProofTest.sol';

contract VotingStrategyTest is BaseProofTest {
  address constant DATA_WAREHOUSE = address(123);

  function setUp() public {
    votingStrategy = new VSTest(DATA_WAREHOUSE);

    _getRootsAndProofs();
  }

  function testContractCreation() public {
    vm.expectRevert(bytes(Errors.INVALID_DATA_WAREHOUSE));
    new VotingStrategy(address(0));
  }

  function testGetVotingPowerAave() public {
    uint256 aavePower = votingStrategy.getVotingPower(
      IBaseVotingStrategy(address(votingStrategy)).AAVE(),
      uint128(aaveProofs.baseBalanceSlotRaw),
      aaveProofs.balanceSlotValue,
      proofBlockHash
    );

    assertEq(aavePower, aaveProofs.votingPower);
  }

  function testGetVotingPowerAAave() public {
    uint256 votingBalancePower = votingStrategy.getVotingPower(
      IBaseVotingStrategy(address(votingStrategy)).A_AAVE(),
      uint128(aAaveProofs.baseBalanceSlotRaw),
      aAaveProofs.balanceSlotValue,
      proofBlockHash
    );

    uint256 delegatedPower = votingStrategy.getVotingPower(
      IBaseVotingStrategy(address(votingStrategy)).A_AAVE(),
      uint128(aAaveProofs.delegationSlotRaw),
      aAaveProofs.delegationBalanceSlotValue,
      proofBlockHash
    );

    uint256 totalPower = delegatedPower;
    if (!aAaveProofs.delegating) {
      assertEq(votingBalancePower, aAaveProofs.balance);
      totalPower += votingBalancePower;
    }

    assertEq(totalPower, aAaveProofs.votingPower);
  }

  function testGetVotingPowerStkAave() public {
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getRegisteredSlot.selector,
        proofBlockHash,
        address(IBaseVotingStrategy(address(votingStrategy)).STK_AAVE()),
        bytes32(votingStrategy.STK_AAVE_SLASHING_EXCHANGE_RATE_SLOT())
      ),
      abi.encode(stkAaveProofs.exchangeRate)
    );
    uint256 aavePower = votingStrategy.getVotingPower(
      IBaseVotingStrategy(address(votingStrategy)).STK_AAVE(),
      uint128(stkAaveProofs.baseBalanceSlotRaw),
      stkAaveProofs.balanceSlotValue,
      proofBlockHash
    );

    assertEq(aavePower, stkAaveProofs.votingPower);
  }

  function testHasRoots() public {
    bytes32 blockHash = keccak256(abi.encode(1));
    bytes32 returnBytes32 = keccak256(abi.encode(1));

    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getStorageRoots.selector,
        address(IBaseVotingStrategy(address(votingStrategy)).AAVE()),
        blockHash
      ),
      abi.encode(returnBytes32)
    );
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getStorageRoots.selector,
        address(IBaseVotingStrategy(address(votingStrategy)).STK_AAVE()),
        blockHash
      ),
      abi.encode(returnBytes32)
    );
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getStorageRoots.selector,
        address(IBaseVotingStrategy(address(votingStrategy)).A_AAVE()),
        blockHash
      ),
      abi.encode(returnBytes32)
    );
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getRegisteredSlot.selector,
        blockHash,
        address(IBaseVotingStrategy(address(votingStrategy)).STK_AAVE()),
        bytes32(votingStrategy.STK_AAVE_SLASHING_EXCHANGE_RATE_SLOT())
      ),
      abi.encode(returnBytes32)
    );
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getRegisteredSlot.selector,
        blockHash,
        address(IBaseVotingStrategy(address(votingStrategy)).A_AAVE()),
        bytes32(
          uint256(
            IBaseVotingStrategy(address(votingStrategy))
              .A_AAVE_DELEGATED_STATE_SLOT()
          )
        )
      ),
      abi.encode(returnBytes32)
    );
    votingStrategy.hasRequiredRoots(blockHash);
  }

  function testHasRootsWhenNotAaveRoots() public {
    bytes32 blockHash = keccak256(abi.encode(1));

    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getStorageRoots.selector,
        address(IBaseVotingStrategy(address(votingStrategy)).AAVE()),
        blockHash
      ),
      abi.encode(bytes32(0))
    );
    vm.expectRevert(bytes(Errors.MISSING_AAVE_ROOTS));
    votingStrategy.hasRequiredRoots(blockHash);
  }

  function testHasRootsWhenNotStkAaveRoots() public {
    bytes32 blockHash = keccak256(abi.encode(1));
    bytes32 returnBytes32 = keccak256(abi.encode(1));

    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getStorageRoots.selector,
        address(IBaseVotingStrategy(address(votingStrategy)).AAVE()),
        blockHash
      ),
      abi.encode(returnBytes32)
    );
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getStorageRoots.selector,
        address(IBaseVotingStrategy(address(votingStrategy)).STK_AAVE()),
        blockHash
      ),
      abi.encode(bytes32(0))
    );
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getRegisteredSlot.selector,
        blockHash,
        address(IBaseVotingStrategy(address(votingStrategy)).STK_AAVE()),
        bytes32(votingStrategy.STK_AAVE_SLASHING_EXCHANGE_RATE_SLOT())
      ),
      abi.encode(returnBytes32)
    );
    vm.expectRevert(bytes(Errors.MISSING_STK_AAVE_ROOTS));
    votingStrategy.hasRequiredRoots(blockHash);
  }

  function testHasRootsWhenNotStkAaveExchangeRate() public {
    bytes32 blockHash = keccak256(abi.encode(1));
    bytes32 returnBytes32 = keccak256(abi.encode(1));

    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getStorageRoots.selector,
        address(IBaseVotingStrategy(address(votingStrategy)).AAVE()),
        blockHash
      ),
      abi.encode(returnBytes32)
    );
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getStorageRoots.selector,
        address(IBaseVotingStrategy(address(votingStrategy)).STK_AAVE()),
        blockHash
      ),
      abi.encode(returnBytes32)
    );
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getStorageRoots.selector,
        address(IBaseVotingStrategy(address(votingStrategy)).A_AAVE()),
        blockHash
      ),
      abi.encode(returnBytes32)
    );
    vm.mockCall(
      address(votingStrategy.DATA_WAREHOUSE()),
      abi.encodeWithSelector(
        IDataWarehouse.getRegisteredSlot.selector,
        blockHash,
        address(IBaseVotingStrategy(address(votingStrategy)).STK_AAVE()),
        bytes32(votingStrategy.STK_AAVE_SLASHING_EXCHANGE_RATE_SLOT())
      ),
      abi.encode(0)
    );
    vm.expectRevert(bytes(Errors.MISSING_STK_AAVE_SLASHING_EXCHANGE_RATE));
    votingStrategy.hasRequiredRoots(blockHash);
  }
}
