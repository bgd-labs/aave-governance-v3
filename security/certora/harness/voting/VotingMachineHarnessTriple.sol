// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VotingMachineHarness} from './VotingMachineHarness.sol';
import {IDataWarehouse, IVotingStrategy} from '../../../src/contracts/voting/interfaces/IVotingMachineWithProofs.sol';


/**
 * @title VotingMachineHarnessTriple
 * Adds the submitVoteTripleProof method, this is separated to avoid using
 * loop_iter=3 throughout.
 */
contract VotingMachineHarnessTriple is VotingMachineHarness {
  
  constructor(
    address crossChainController,
    uint256 gasLimit,
    uint256 l1VotingPortalChainId,
    IVotingStrategy votingStrategy,
    address l1VotingPortal,
    address governance
  ) VotingMachineHarness(
    crossChainController,
    gasLimit,
    l1VotingPortalChainId,
    votingStrategy,
    l1VotingPortal,
    governance
  ) {
  }

  /**
   * @notice A variant of submitVote that accepts three proofs.
   */
  function submitVoteTripleProof(
    uint256 proposalId,
    bool support,
    VotingBalanceProof calldata proof1,
    VotingBalanceProof calldata proof2,
    VotingBalanceProof calldata proof3
  ) external {
    VotingBalanceProof[] memory proofs = new VotingBalanceProof[](3);

    // Copy proofs
    proofs[0].underlyingAsset = proof1.underlyingAsset;
    proofs[0].slot = proof1.slot;
    proofs[0].proof = proof1.proof;
    
    proofs[1].underlyingAsset = proof2.underlyingAsset;
    proofs[1].slot = proof2.slot;
    proofs[1].proof = proof2.proof;
    
    proofs[2].underlyingAsset = proof3.underlyingAsset;
    proofs[2].slot = proof3.slot;
    proofs[2].proof = proof3.proof;

    // To convert `proofs` into `calldata` we make an external call using `this`.
    // Unfortunately this makes the msg.sender into the contract, so we call submitVoteFromVoter.
    this.submitVoteFromVoter(msg.sender, proposalId, support, proofs);
  }
}
