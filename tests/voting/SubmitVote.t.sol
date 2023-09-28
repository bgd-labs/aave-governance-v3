// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IVotingMachineWithProofs} from '../../src/contracts/voting/interfaces/IVotingMachineWithProofs.sol';
import {IDataWarehouse} from '../../src/contracts/voting/interfaces/IDataWarehouse.sol';
import {IVotingStrategy} from '../../src/contracts/voting/interfaces/IVotingStrategy.sol';
import {DataWarehouse} from '../../src/contracts/voting/DataWarehouse.sol';
import {VotingStrategy} from '../../src/contracts/voting/VotingStrategy.sol';
import {VotingMachineWithProofs, StateProofVerifier} from '../../src/contracts/voting/VotingMachineWithProofs.sol';
import {SlotUtils} from '../../src/contracts/libraries/SlotUtils.sol';
import {BaseProofTest} from '../utils/BaseProofTest.sol';
import {VotingStrategyTest} from '../../scripts/extendedContracts/StrategiesTest.sol';

contract VotingMachine is VotingMachineWithProofs {
  constructor(
    IVotingStrategy votingStrategy,
    address governance
  ) VotingMachineWithProofs(votingStrategy, governance) {}

  function setProposalsVoteConfiguration(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external {
    _proposalsVoteConfiguration[proposalId] = IVotingMachineWithProofs
      .ProposalVoteConfiguration({
        votingDuration: votingDuration,
        l1ProposalBlockHash: blockHash
      });
  }

  function setProposalVote(
    uint256 proposalId,
    address voter,
    bool support,
    uint248 votingPower
  ) external {
    _proposals[proposalId].votes[voter].votingPower = votingPower;
    _proposals[proposalId].votes[voter].support = support;
  }

  function setProposal(uint256 proposalId) external {
    Proposal storage newProposal = _proposals[proposalId];
    newProposal.id = proposalId;
  }

  function _sendVoteResults(
    uint256 proposalId,
    uint256 forVotes,
    uint256 againstVotes
  ) internal override {}
}

contract SubmitVoteTest is BaseProofTest {
  IVotingMachineWithProofs votingMachine;

  uint256 constant PROPOSAL_ID = 0;

  uint24 constant VOTING_DURATION = 600;

  bytes32 returnBytes32 = keccak256(abi.encode(1));

  function setUp() public {
    // this is needed instead of mocks to test gas
    // deploy dependencies
    dataWarehouse = new DataWarehouse();

    votingStrategy = new VotingStrategyTest(address(dataWarehouse));

    // get roots and proofs
    _getRootsAndProofs();

    votingMachine = new VotingMachine(votingStrategy, GOVERNANCE);

    // register roots and values
    _initializeRepresentatives();
    _initializeAave();
    _initializeStkAave();
    _initializeAAave();

    _createVote(PROPOSAL_ID, VOTING_DURATION);
  }

  // TEST SUBMIT VOTE
  function testSubmitVoteInSupport_AAVE() public {
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        1
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: AAVE,
      slot: uint128(aaveProofs.baseBalanceSlotRaw),
      proof: aaveProofs.balanceStorageProofRlp
    });

    hoax(proofVoter);
    votingMachine.submitVote(PROPOSAL_ID, true, votingBalanceProofs);
  }

  function testSubmitVoteInSupport_AAVE_and_STK_AAVE() public {
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        2
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: AAVE,
      slot: uint128(aaveProofs.baseBalanceSlotRaw),
      proof: aaveProofs.balanceStorageProofRlp
    });
    votingBalanceProofs[1] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: STK_AAVE,
      slot: uint128(stkAaveProofs.baseBalanceSlotRaw),
      proof: stkAaveProofs.balanceStorageProofRlp
    });

    hoax(proofVoter);
    votingMachine.submitVote(PROPOSAL_ID, true, votingBalanceProofs);
  }

  function testSubmitVoteInSupport_AAVE_and_STK_AAVE_and_A_AAVE() public {
    uint256 votingProofs = 3;
    if (aAaveProofs.delegating) {
      votingProofs = 4;
    }
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        votingProofs
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: AAVE,
      slot: uint128(aaveProofs.baseBalanceSlotRaw),
      proof: aaveProofs.balanceStorageProofRlp
    });
    votingBalanceProofs[1] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: STK_AAVE,
      slot: uint128(stkAaveProofs.baseBalanceSlotRaw),
      proof: stkAaveProofs.balanceStorageProofRlp
    });
    votingBalanceProofs[2] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: A_AAVE,
      slot: uint128(aAaveProofs.baseBalanceSlotRaw),
      proof: aAaveProofs.balanceStorageProofRlp
    });
    if (aAaveProofs.delegating) {
      votingBalanceProofs[3] = IVotingMachineWithProofs.VotingBalanceProof({
        underlyingAsset: A_AAVE,
        slot: uint128(aAaveProofs.delegationSlotRaw),
        proof: aAaveProofs.aAaveDelegationStorageProofRlp
      });
    }

    hoax(proofVoter);
    votingMachine.submitVote(PROPOSAL_ID, true, votingBalanceProofs);
  }

  function testSubmitVoteAsRepresentative_AAVE_and_STK_AAVE_and_A_AAVE()
    public
  {
    uint256 votingProofs = 3;
    if (aAaveProofs.delegating) {
      votingProofs = 4;
    }
    IVotingMachineWithProofs.VotingBalanceProof[]
      memory votingBalanceProofs = new IVotingMachineWithProofs.VotingBalanceProof[](
        votingProofs
      );

    votingBalanceProofs[0] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: AAVE,
      slot: uint128(aaveProofs.baseBalanceSlotRaw),
      proof: aaveProofs.balanceStorageProofRlp
    });
    votingBalanceProofs[1] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: STK_AAVE,
      slot: uint128(stkAaveProofs.baseBalanceSlotRaw),
      proof: stkAaveProofs.balanceStorageProofRlp
    });
    votingBalanceProofs[2] = IVotingMachineWithProofs.VotingBalanceProof({
      underlyingAsset: A_AAVE,
      slot: uint128(aAaveProofs.baseBalanceSlotRaw),
      proof: aAaveProofs.balanceStorageProofRlp
    });
    if (aAaveProofs.delegating) {
      votingBalanceProofs[3] = IVotingMachineWithProofs.VotingBalanceProof({
        underlyingAsset: A_AAVE,
        slot: uint128(aAaveProofs.delegationSlotRaw),
        proof: aAaveProofs.aAaveDelegationStorageProofRlp
      });
    }

    address representativeAddress = address(
      uint160(representatives.representative)
    );

    hoax(representativeAddress);
    votingMachine.submitVoteAsRepresentative(
      PROPOSAL_ID,
      true,
      representatives.represented,
      representatives.proofOfRepresentative,
      votingBalanceProofs
    );

    IVotingMachineWithProofs.Vote memory vote = votingMachine
      .getUserProposalVote(representatives.represented, PROPOSAL_ID);

    assertEq(vote.support, true);
    assertEq(vote.votingPower, 2600000000000000000000);
  }

  function testRepresentativeSlot() public {
    bytes32 slot = SlotUtils.getRepresentativeSlotHash(
      representatives.represented,
      block.chainid,
      representatives.representativesSlotRaw
    );

    assertEq(
      keccak256(abi.encode(slot)),
      keccak256(abi.encode(representatives.representativesSlotHash))
    );
  }

  // HELPER METHODS
  function _createVote(uint256 proposalId, uint24 votingDuration) public {
    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      proofBlockHash,
      votingDuration
    );
    votingMachine.startProposalVote(proposalId);
  }
}
