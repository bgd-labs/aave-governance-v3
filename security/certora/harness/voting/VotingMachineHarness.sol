// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VotingMachine} from '../../../../src/contracts/voting/VotingMachine.sol';
import {IDataWarehouse, IVotingStrategy} from '../../../../src/contracts/voting/interfaces/IVotingMachineWithProofs.sol';


/**
 * @title VotingMachineHarness
 * Harnessing VotingMachine to handle arrays of VotingBalanceProof.
 */
contract VotingMachineHarness is VotingMachine {
  
  constructor(
    address crossChainController,
    uint256 gasLimit,
    uint256 l1VotingPortalChainId,
    IVotingStrategy votingStrategy,
    address l1VotingPortal,
    address governance
  ) VotingMachine(
    crossChainController,
    gasLimit,
    l1VotingPortalChainId,
    votingStrategy,
    l1VotingPortal,
    governance
  ) {
  }

  /**
   * @notice A variant of submitVote that accepts a single VotingBalanceProof.
   */
  function submitVoteSingleProof(
    uint256 proposalId,
    bool support,
    VotingBalanceProof calldata proof
  ) external {
    VotingBalanceProof[] memory proofs = new VotingBalanceProof[](1);

    // Copy proof
    proofs[0].underlyingAsset = proof.underlyingAsset;
    proofs[0].slot = proof.slot;
    proofs[0].proof = proof.proof;

    // To convert `proofs` into `calldata` we make an external call using `this`.
    // Unfortunately this makes the msg.sender into the contract, so we call submitVoteFromVoter.
    this.submitVoteFromVoter(msg.sender, proposalId, support, proofs);
  }
 
  // Hack - see submitVoteSingleProof
  function submitVoteFromVoter(
    address voter,
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external {
    require(msg.sender == address(this));  // Safety measure
    _submitVote(voter, proposalId, support, votingBalanceProofs);
  }

  /**
   * @notice For testing `_createBridgedProposalVote`, e.g. in `newProposalUnusedId`.
   */
  function createProposalVoteHarness(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external {
    _createBridgedProposalVote(proposalId, blockHash, votingDuration);
  }

  // Needed for proposalIdIsImmutable rule
  function getIdOfProposal(
    uint256 proposalId
  ) external view returns (uint256) {
    return _proposals[proposalId].id;
  }
}
