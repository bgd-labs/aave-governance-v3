/// ============================================================================
/// Miscellaneous Rules
/// ============================================================================

import "power_summary.spec";


// Sending results =============================================================

/// @title Can only send results for finished votes
rule sendOnlyFinishedVote(uint256 proposalId) {
    env e;
    IVotingMachineWithProofs.ProposalState state = getProposalState(e, proposalId);

    closeAndSendVote(e, proposalId);

    assert state == IVotingMachineWithProofs.ProposalState.Finished;
}


// Particular voting methods ===================================================

/// @title Utility function for getting raw voting power from proof
function _getRawSlotPower(
    IVotingMachineWithProofs.VotingBalanceProof proof
) returns uint256 {
    bytes32 blockHash;  // Value is unimportant due to summarization of _getStorage
    bytes32 slotHash;  // Value is unimportant due to summarization of _getStorage
    StateProofVerifier.SlotValue slotValue = _getStorage(
        proof.underlyingAsset, blockHash, slotHash, proof.proof
    );
    return slotValue.value;
}


/// @title Utility function for getting voting power from proof
function _getVotingPowerFromProof(
    IVotingMachineWithProofs.VotingBalanceProof proof
) returns uint256 {
    uint256 raw_power = _getRawSlotPower(proof);
    return mockVotingPower(proof.underlyingAsset, proof.slot, raw_power);
}


/** @title Single proof verification
 * Verifies the following properties for voting using `submitVoteSingleProof`:
 * - A vote is rejected if either:
 *   a. User's registered voted power for the proposal is not zero (voting twice)
 *   b. User's voting power is zero
 *   c. Proposal's state is not `Active`
 * - After voting, user's registered support and voted power are the same as the vote
 * - The total votes tally is updated correctly
 */
rule submitSingleProofVerification(
    uint256 proposalId,
    bool support,
    IVotingMachineWithProofs.VotingBalanceProof proof
) {
    env e;
    IVotingMachineWithProofs.ProposalWithoutVotes pre = getProposalById(proposalId);

    // If `votePre.votingPower` is not zero, it means user already voted
    IVotingMachineWithProofs.Vote votePre = getUserProposalVote(e.msg.sender, proposalId);

    // If `votePower` is zero, the user's vote will be rejected
    uint256 voterPower = _getVotingPowerFromProof(proof);

    // If the proposal state is not active, the user's vote will be rejected
    IVotingMachineWithProofs.ProposalState state = getProposalState(e, proposalId);

    submitVoteSingleProof(e, proposalId, support, proof);

    assert (
        (votePre.votingPower == 0) &&
        (voterPower >  0) &&
        (state == IVotingMachineWithProofs.ProposalState.Active)
    );

    IVotingMachineWithProofs.Vote postVote = getUserProposalVote(e.msg.sender, proposalId);
    assert postVote.support == support;

    // Since `voterPower` and `postVote.votingPower` have different types, we cast both
    // to `mathint`.
    mathint mathVoterPower = to_mathint(voterPower);
    mathint mathPostPower = to_mathint(postVote.votingPower);
    assert mathPostPower == mathVoterPower;

    IVotingMachineWithProofs.ProposalWithoutVotes post = getProposalById(proposalId);
    
    // Votes can only increase
    assert post.forVotes >= pre.forVotes;
    assert post.againstVotes >= pre.againstVotes;

    uint128 forChange = assert_uint128(post.forVotes - pre.forVotes);
    uint128 againstChange = assert_uint128(post.againstVotes - pre.againstVotes);
    uint128 castVoterPower = assert_uint128(postVote.votingPower);
    assert support => (forChange == castVoterPower) && (againstChange == 0);
    assert !support => (forChange == 0) && (againstChange == castVoterPower);
}


/// @title Triple proof verification
rule submitTripleProofVerification(
    uint256 proposalId,
    bool support,
    IVotingMachineWithProofs.VotingBalanceProof proof1,
    IVotingMachineWithProofs.VotingBalanceProof proof2,
    IVotingMachineWithProofs.VotingBalanceProof proof3
) {
    require proof1.underlyingAsset == _VotingStrategy.AAVE();
    require proof1.slot == 0;
    require proof1.proof.length < max_uint32;  // Avoid calldata pointer overflow
    require proof2.underlyingAsset == _VotingStrategy.STK_AAVE();
    require proof2.slot == 0;
    require proof2.proof.length < max_uint32;  // Avoid calldata pointer overflow
    require proof3.underlyingAsset == _VotingStrategy.A_AAVE();
    require proof3.slot == 52;
    require proof3.proof.length < max_uint32;  // Avoid calldata pointer overflow

    env e;

    uint256 power1 = _getVotingPowerFromProof(proof1);
    uint256 power2 = _getVotingPowerFromProof(proof2);
    uint256 power3 = _getVotingPowerFromProof(proof3);
    mathint power = power1 + power2 + power3;

    submitVoteTripleProof(e, proposalId, support, proof1, proof2, proof3);

    IVotingMachineWithProofs.Vote postVote = getUserProposalVote(e.msg.sender, proposalId);
    assert (
        to_mathint(postVote.votingPower) == power &&
        postVote.support == support
    );
}


/// @title Are two proofs equivalent
function isEquivalent(
    IVotingMachineWithProofs.VotingBalanceProof proof1,
    IVotingMachineWithProofs.VotingBalanceProof proof2
) returns bool {
    return (
        proof1.underlyingAsset == proof2.underlyingAsset &&
        proof1.slot == proof2.slot
    );
}

/// @title Reject equivalent proofs
rule rejectEquivalentProofs(
    uint256 proposalId,
    bool support,
    IVotingMachineWithProofs.VotingBalanceProof proof1,
    IVotingMachineWithProofs.VotingBalanceProof proof2,
    IVotingMachineWithProofs.VotingBalanceProof proof3
) {
    // Prevent calldata pointer overflow
    require (
        proof1.proof.length < max_uint32 &&
        proof2.proof.length < max_uint32 &&
        proof3.proof.length < max_uint32
    );
    require (
        isEquivalent(proof1, proof2) ||
        isEquivalent(proof1, proof3) ||
        isEquivalent(proof2, proof3)
    );

    env e;
    submitVoteTripleProof@withrevert(e, proposalId, support, proof1, proof2, proof3);
    assert lastReverted;
}


// setup self check - reachability of currentContract external functions
rule method_reachability(method f) filtered {
    f -> filteredMethods(f)
} {
  env e;
  calldataarg arg;
  f(e, arg);
  satisfy true;
}
