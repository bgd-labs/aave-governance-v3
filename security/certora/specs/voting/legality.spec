/// ============================================================================
/// Voting legality
/// ============================================================================

/* Summary
 * -------
 * The spec, together with `voting_and_tally.spec` and `states.spec`, shows that:
 * A vote can be rejected only for one of the following reasons (otherwise must be
 * accepted):
 * - Voting twice on behalf of particular user (rule `votedPowerIsImmutable` together
 *   with results from `voting_and_tally.spec`)
 * - Voting before vote start (rule `onlyValidProposalCanChangeTally` and `states.spec`)
 * - Voting after vote end (rule `onlyValidProposalCanChangeTally` and `states.spec`)
 * - Voting with 0 voting power (rule `legalVote`)
 */

import "setup.spec";


/// @title Is the proposal's block hash non-zero
function is_proposalHashNonZero(uint256 proposalId) returns bool {
    IVotingMachineWithProofs.ProposalVoteConfiguration conf = (
        getProposalVoteConfiguration(proposalId)
    );
    return conf.l1ProposalBlockHash != to_bytes32(0);
}


/** @title Is the proposal Active
 * @return False if the proposal's state is `NotCreated`, true otherwise.
 * @notice By rule `proposalLegalStates` the state `NotCreated` is equivalent to
 * `endTime` being zero.
 */
function is_proposalCreated(uint256 proposalId) returns bool {
    IVotingMachineWithProofs.ProposalWithoutVotes proposal = getProposalById(proposalId);
    return proposal.endTime != 0;
}


invariant createdVoteHasNonZeroHash(uint256 proposalId)
    is_proposalCreated(proposalId) => is_proposalHashNonZero(proposalId)
    filtered {
        f -> filteredMethods(f)
    }


/** @title Stored voting power is immutable (once positive)
 * Proves that stored voting power can change only when the original value is zero,
 * and that once it is positive it is immutable. This rule, together with the
 * previous section proves that a voter cannot vote twice.
 */
rule votedPowerIsImmutable(method f, address voter, uint256 proposalId) filtered {
    f -> filteredMethods(f)
} {
    IVotingMachineWithProofs.Vote pre = getUserProposalVote(voter, proposalId);

    env e;
    calldataarg args;
    f(e, args);

    IVotingMachineWithProofs.Vote post = getUserProposalVote(voter, proposalId);

    assert pre.votingPower > 0 => post.votingPower == pre.votingPower;
    assert post.votingPower != pre.votingPower => pre.votingPower == 0;
}


/// @title Vote tally can change only for active and properly configured proposals
rule onlyValidProposalCanChangeTally(method f, uint256 proposalId) filtered {
    f -> filteredMethods(f)
} {
    requireInvariant createdVoteHasNonZeroHash(proposalId);

    IVotingMachineWithProofs.ProposalWithoutVotes pre = getProposalById(proposalId);
    IVotingMachineWithProofs.ProposalVoteConfiguration conf = (
        getProposalVoteConfiguration(proposalId)
    );

    env e;
    IVotingMachineWithProofs.ProposalState state = getProposalState(e, proposalId);

    calldataarg args;
    f(e, args);
    
    IVotingMachineWithProofs.ProposalWithoutVotes post = getProposalById(proposalId);

    bool is_tallyChanged = (
        (pre.forVotes != post.forVotes) || (pre.againstVotes != post.againstVotes)
    );
    assert is_tallyChanged => (
        (state == IVotingMachineWithProofs.ProposalState.Active) &&
        (conf.l1ProposalBlockHash != to_bytes32(0))
    );
}


/** @title Vote tally may change only if voter had zero stored voting power before
 * and positive after.
 */
rule legalVote(method f, uint256 proposalId, address voter) filtered {
    f -> !f.isView && filteredMethods(f)
} {
    IVotingMachineWithProofs.ProposalWithoutVotes pre = getProposalById(proposalId);
    IVotingMachineWithProofs.Vote preVote = getUserProposalVote(voter, proposalId);

    env e;
    calldataarg args;
    f(e, args);

    IVotingMachineWithProofs.ProposalWithoutVotes post = getProposalById(proposalId);
    IVotingMachineWithProofs.Vote postVote = getUserProposalVote(voter, proposalId);

    bool is_tallyChanged = (
        (pre.forVotes != post.forVotes) || (pre.againstVotes != post.againstVotes)
    );
    bool is_voterChanged = (preVote.votingPower != postVote.votingPower);
    assert (
        (is_tallyChanged && is_voterChanged) => 
        (preVote.votingPower == 0 && postVote.votingPower > 0)
    );
}

use rule method_reachability;
