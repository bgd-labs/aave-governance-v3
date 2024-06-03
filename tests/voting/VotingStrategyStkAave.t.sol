// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {DelegationMode} from 'aave-token-v3/DelegationAwareBalance.sol';

import {IDataWarehouse} from '../../src/contracts/voting/DataWarehouse.sol';
import {VotingStrategy, IVotingStrategy, IBaseVotingStrategy} from '../../src/contracts/voting/VotingStrategy.sol';
import {SlotUtils} from '../../src/contracts/libraries/SlotUtils.sol';

contract VotingStrategyStkAaveTest is Test {
  address DATA_WAREHOUSE = address(65536+123);
  bytes32 constant BLOCK_HASH =
    0x0a7c36db26203276b9430a46faaba9ce76732c5b7c11ef07b39e81a2690591b7;
  address constant VOTER = 0x6D603081563784dB3f83ef1F65Cc389D94365Ac9;
  uint128 constant SLOT = uint128(0);
  uint256 constant EXCHANGE_RATE_SLOT = 81;

  IVotingStrategy votingStrategy;

  function setUp() public {
    votingStrategy = new VotingStrategy(address(DATA_WAREHOUSE));
  }

  function testFuzzGetPowerOfStkAaveToken(
    bytes32 blockHash,
    uint256 slashingExchangeRate,
    uint104 userBalance,
    uint104 delegatedPropositionPower,
    uint104 delegatedVotingPower,
    uint8 delegationModeRaw
  ) public {
    vm.assume(slashingExchangeRate >= 1e18 && slashingExchangeRate < 1e21);
    DelegationMode delegationMode = DelegationMode(delegationModeRaw % 4);

    // delegated voting power
    uint256 votingPower = (delegatedVotingPower /
      votingStrategy.POWER_SCALE_FACTOR()) *
      votingStrategy.POWER_SCALE_FACTOR();

    if (
      delegationMode != DelegationMode.VOTING_DELEGATED &&
      delegationMode != DelegationMode.FULL_POWER_DELEGATED
    ) votingPower += userBalance;

    votingPower =
      (votingPower *
        votingStrategy.STK_AAVE_SLASHING_EXCHANGE_RATE_PRECISION()) /
      slashingExchangeRate;

    uint256 balanceRaw = uint256(
      bytes32(
        abi.encodePacked(
          delegationMode,
          uint72(delegatedVotingPower / votingStrategy.POWER_SCALE_FACTOR()),
          uint72(
            delegatedPropositionPower / votingStrategy.POWER_SCALE_FACTOR()
          ),
          userBalance
        )
      )
    );

    vm.mockCall(
      DATA_WAREHOUSE,
      abi.encodeWithSelector(
        IDataWarehouse.getRegisteredSlot.selector,
        blockHash,
        IBaseVotingStrategy(address(votingStrategy)).STK_AAVE(),
        bytes32(EXCHANGE_RATE_SLOT)
      ),
      abi.encode(slashingExchangeRate)
    );
    uint256 votingBalancePower = votingStrategy.getVotingPower(
      IBaseVotingStrategy(address(votingStrategy)).STK_AAVE(),
      SLOT,
      balanceRaw,
      blockHash
    );

    assertEq(votingBalancePower, votingPower);
  }
}
