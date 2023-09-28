// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/console.sol';
import {DataWarehouse, IDataWarehouse} from '../../src/contracts/voting/DataWarehouse.sol';
import {VotingStrategy, IVotingStrategy} from '../../src/contracts/voting/VotingStrategy.sol';
import {StateProofVerifier} from '../../src/contracts/voting/libs/StateProofVerifier.sol';
import {SlotUtils} from '../../src/contracts/libraries/SlotUtils.sol';
import {BaseProofTest, VotingStrategyTest} from '../utils/BaseProofTest.sol';

contract VotingStrategyATokenTest is BaseProofTest {
  StateProofVerifier.SlotValue internal power;
  StateProofVerifier.SlotValue internal delegationPower;

  function setUp() public {
    dataWarehouse = new DataWarehouse();

    votingStrategy = new VotingStrategyTest(address(dataWarehouse));

    // get roots and proofs
    _getRootsAndProofs();
    // register roots and values
    _initializeAAave();

    power = dataWarehouse.getStorage(
      A_AAVE,
      proofBlockHash,
      SlotUtils.getAccountSlotHash(
        proofVoter,
        uint128(aAaveProofs.baseBalanceSlotRaw)
      ),
      aAaveProofs.balanceStorageProofRlp
    );

    delegationPower = dataWarehouse.getStorage(
      A_AAVE,
      proofBlockHash,
      SlotUtils.getAccountSlotHash(
        proofVoter,
        uint128(aAaveProofs.delegationSlotRaw)
      ),
      aAaveProofs.aAaveDelegationStorageProofRlp
    );
  }

  function testGetPowerOfAToken() public {
    uint256 votingBalancePower = votingStrategy.getVotingPower(
      A_AAVE,
      uint128(aAaveProofs.baseBalanceSlotRaw),
      power.value,
      proofBlockHash
    );
    uint256 votingDelegationPower = votingStrategy.getVotingPower(
      A_AAVE,
      uint128(aAaveProofs.delegationSlotRaw),
      delegationPower.value,
      proofBlockHash
    );

    uint256 totalPower = votingDelegationPower;
    if (!aAaveProofs.delegating) {
      assertEq(votingBalancePower, aAaveProofs.balance);
      totalPower += votingBalancePower;
    }

    assertEq(totalPower, aAaveProofs.votingPower);
  }
}
