/// ============================================================================
/// Proposal states
/// ============================================================================

import "setup.spec";
import "proposal_config.spec";

use invariant startedProposalHasConfig;
use invariant proposalHasNonzeroDuration;


// Utilities ===================================================================

function proposalStartTime(uint256 proposalId) returns uint40 {
    IVotingMachineWithProofs.ProposalWithoutVotes proposal = getProposalById(proposalId);
    return proposal.startTime;
}


function proposalEndTime(uint256 proposalId) returns uint40 {
    IVotingMachineWithProofs.ProposalWithoutVotes proposal = getProposalById(proposalId);
    return proposal.endTime;
}


function proposalVotingDuration(uint256 proposalId) returns uint24 {
    IVotingMachineWithProofs.ProposalVoteConfiguration conf = (
        getProposalVoteConfiguration(proposalId)
    );
    return conf.votingDuration;
}


/// @notice: ASSUMES `state.NotCreated <=> endTime != 0`
function isProposalStarted(uint256 proposalId) returns bool {
    IVotingMachineWithProofs.ProposalWithoutVotes proposal = getProposalById(proposalId);
    return proposal.endTime != 0;
}

// Rules =======================================================================

/// @title A proposal's vote start time is before its end time
invariant startsBeforeEnds(uint256 proposalId)
    (
        (proposalStartTime(proposalId) <= proposalEndTime(proposalId)) &&
        (isProposalStarted(proposalId) => (
            proposalStartTime(proposalId) < proposalEndTime(proposalId)
        ))
    )
    {
        preserved {
            // Without this one can create a proposal with `l1ProposalBlockHash` zero
            requireInvariant startedProposalHasConfig(proposalId);

            // Without this one can start a vote with zero duration
            requireInvariant proposalHasNonzeroDuration(proposalId);
        }
    }


/// @title A started proposal's end time is the start time plus voting duration
invariant startsStrictlyBeforeEnds(uint256 proposalId)
    isProposalStarted(proposalId) => (
        to_mathint(proposalEndTime(proposalId)) ==
        proposalStartTime(proposalId) + proposalVotingDuration(proposalId)
    )
    {
        preserved {
            // Without this one can create a proposal with `l1ProposalBlockHash` zero
            requireInvariant startedProposalHasConfig(proposalId);
        }
    }


/// @title A proposal's valid states
rule proposalLegalStates(uint256 proposalId) {
    env e;

    IVotingMachineWithProofs.ProposalWithoutVotes proposal = getProposalById(proposalId);
    IVotingMachineWithProofs.ProposalState state = getProposalState(e, proposalId);

    // The code casts `block.timestamp` to `uint40`, so we do the same
    uint40 t = require_uint40(e.block.timestamp);

    // `NotCreated` state is the same as `endTime == 0`
    assert (
        (state == IVotingMachineWithProofs.ProposalState.NotCreated) <=>
        (proposal.endTime == 0)
    );

    assert (
        (state == IVotingMachineWithProofs.ProposalState.Active) <=>
        ((proposal.endTime != 0) && (t <= proposal.endTime))
    );

    // After `endTime` the state cannot be `Active`
    assert (t > proposal.endTime) => (state != IVotingMachineWithProofs.ProposalState.Active);

    assert (
        (state == IVotingMachineWithProofs.ProposalState.Finished) <=>
        ((proposal.endTime != 0) && (t > proposal.endTime) && !proposal.sentToGovernance)
    );

    assert (
        (state == IVotingMachineWithProofs.ProposalState.SentToGovernance) <=>
        ((proposal.endTime != 0) && (t > proposal.endTime) && proposal.sentToGovernance)
    );

    // Must be in one of four states
    assert (
        state == IVotingMachineWithProofs.ProposalState.NotCreated ||
        state == IVotingMachineWithProofs.ProposalState.Active ||
        state == IVotingMachineWithProofs.ProposalState.Finished ||
        state == IVotingMachineWithProofs.ProposalState.SentToGovernance
    );
}


/// @title A proposal's valid state transitions by method call
rule proposalMethodStateTransitionCompliance(method f, uint256 proposalId) {
    env e;

    IVotingMachineWithProofs.ProposalState before = getProposalState(e, proposalId);

    calldataarg args;
    f(e, args);

    IVotingMachineWithProofs.ProposalState after = getProposalState(e, proposalId);

    // `NotCreated` state can be changed only by `startProposalVote`
    assert (
        (before == IVotingMachineWithProofs.ProposalState.NotCreated) =>
        (
            after == before ||
            (
                after == IVotingMachineWithProofs.ProposalState.Active &&
                (
                    f.selector == sig:startProposalVote(uint256).selector ||
                    f.selector == (
                        sig:createProposalVoteHarness(uint256, bytes32, uint24).selector
                    )
                )
            )
        )
    );

    // `Active` state can be changed only in time, not method call
    assert (
        before == IVotingMachineWithProofs.ProposalState.Active => after == before
    );

    // `Finished` state can be changed only using `closeAndSendVote`
    assert (
        (before == IVotingMachineWithProofs.ProposalState.Finished) =>
        (
            after == before ||
            (
                after == IVotingMachineWithProofs.ProposalState.SentToGovernance &&
                f.selector == sig:closeAndSendVote(uint256).selector
            )
        )
    );

    // `SentToGovernance` state is final
    assert (
        before == IVotingMachineWithProofs.ProposalState.SentToGovernance => after == before
    );
}


/// @title A proposal's valid state transitions by time
rule proposalTimeStateTransitionCompliance(uint256 proposalId) {
    env e0;
    IVotingMachineWithProofs.ProposalState before = getProposalState(e0, proposalId);
    
    env e1;

    // Ensure `e1` occurs after `e0`
    // Note the code casts `block.timestamp` to `uint40`, so we do the same
    uint40 t0 = require_uint40(e0.block.timestamp);
    uint40 t1 = require_uint40(e1.block.timestamp);
    require t1 >= t0;
    IVotingMachineWithProofs.ProposalState after = getProposalState(e1, proposalId);

    // `NotCreated` state can be changed only by `startProposalVote`
    assert (
        before == IVotingMachineWithProofs.ProposalState.NotCreated => after == before
    );

    // `Active` state can be changed in time
    assert (
        before == IVotingMachineWithProofs.ProposalState.Active =>
        (
            after == before ||
            (
                t1 > t0 &&
                (
                    after == IVotingMachineWithProofs.ProposalState.Finished ||
                    after == IVotingMachineWithProofs.ProposalState.SentToGovernance
                )
            )
        )
    );

    // `Finished` and `SentToGovernance` states cannot be changed by time alone
    assert (
        (
            before == IVotingMachineWithProofs.ProposalState.Finished ||
            before == IVotingMachineWithProofs.ProposalState.SentToGovernance
        ) => after == before
    );
}


/** @title Proposal immutability
 * Verifies that certain fields of the proposal are immutable (once the proposal is
 * created of course).
 */
rule proposalImmutability(method f, uint256 proposalId) {
    IVotingMachineWithProofs.ProposalWithoutVotes pre = getProposalById(proposalId);

    env e;
    IVotingMachineWithProofs.ProposalState initialState = getProposalState(e, proposalId);
    calldataarg args;
    f(e, args);

    IVotingMachineWithProofs.ProposalWithoutVotes post = getProposalById(proposalId);

    assert (
        (initialState != IVotingMachineWithProofs.ProposalState.NotCreated) =>
        (
            pre.id == post.id &&
            pre.startTime == post.startTime &&
            pre.endTime == post.endTime &&
            pre.creationBlockNumber == post.creationBlockNumber
        )
    );
}


/// @title A created proposal vote's ID is never changed
invariant proposalIdIsImmutable(uint256 proposalId)
    isProposalStarted(proposalId) => (getIdOfProposal(proposalId) == proposalId);
