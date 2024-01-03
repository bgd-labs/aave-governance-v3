/// ============================================================================
/// Proposal configuration
/// ============================================================================

import "setup.spec";


// Utilities ===================================================================

/// @title Proposal's voting duration
function getProposalVotingDuration(uint256 proposalId) returns uint24 {
    IVotingMachineWithProofs.ProposalVoteConfiguration conf = (
        getProposalVoteConfiguration(proposalId)
    );
    return conf.votingDuration;
}


/// @title Has the proposal's config been created
function is_proposalConfigCreated(uint256 proposalId) returns bool {
    IVotingMachineWithProofs.ProposalVoteConfiguration conf = (
        getProposalVoteConfiguration(proposalId)
    );
    return conf.l1ProposalBlockHash != to_bytes32(0);
}


/** @title Is the proposal created
 * @return False if the proposal's state is `NotCreated`, true otherwise.
 * @notice By rule `proposalLegalStates` the state `NotCreated` is equivalent to
 * `endTime` being zero.
 */
function is_proposalStarted(uint256 proposalId) returns bool {
    IVotingMachineWithProofs.ProposalWithoutVotes proposal = getProposalById(proposalId);
    return proposal.endTime != 0;
}


/** @title Does the proposal have the required roots
 * Essentially this verifies that `VotingStrategy.hasRequiredRoots` does not revert.
 * @return true if the roots exist
 */
function is_proposalHasRoots(uint256 proposalId) returns bool { 
    IVotingMachineWithProofs.ProposalVoteConfiguration conf = (
        getProposalVoteConfiguration(proposalId)
    );
    return _VotingStrategy.is_hasRequiredRoots(conf.l1ProposalBlockHash);
}


// Rules =======================================================================

/** @title When starting a proposal vote it already has a config
 * @notice The opposite need not be true - in `_createBridgedProposalVote` the call to
 * `startProposalVote(proposalId)` may fail. Since this is inside a try-catch (see
 * `VotingMachineWithProofs.sol:412`) it will not revert the original call.
 */
invariant startedProposalHasConfig(uint256 proposalId)
    is_proposalStarted(proposalId) => is_proposalConfigCreated(proposalId);


/// @title Once a proposal vote is started the required roots exist
invariant createdProposalHasRoots(uint256 proposalId)
    is_proposalStarted(proposalId) => is_proposalHasRoots(proposalId)
    {
        preserved {
            // Without this one can create a proposal with `l1ProposalBlockHash` zero
            requireInvariant startedProposalHasConfig(proposalId);
        }
    }


/// @title Existing proposal config has non-zero duration
invariant proposalHasNonzeroDuration(uint256 proposalId)
    is_proposalConfigCreated(proposalId) <=> (getProposalVotingDuration(proposalId) != 0);


/// @title New proposal must have unused ID
rule newProposalUnusedId(uint256 proposalId, bytes32 blockHash, uint24 votingDuration) {

    requireInvariant startedProposalHasConfig(proposalId);
    
    env e;
    IVotingMachineWithProofs.ProposalVoteConfiguration preConf = (
        getProposalVoteConfiguration(proposalId)
    );
    IVotingMachineWithProofs.ProposalState preState = getProposalState(e, proposalId);

    createProposalVoteHarness(e, proposalId, blockHash, votingDuration);
    
    IVotingMachineWithProofs.ProposalState postState = getProposalState(e, proposalId);

    // `preConf.l1ProposalBlockHash == to_bytes32(0)` implies the proposal is not created
    assert (
        (preConf.l1ProposalBlockHash == to_bytes32(0)) &&
        (
            (postState != IVotingMachineWithProofs.ProposalState.NotCreated) =>
            (preState == IVotingMachineWithProofs.ProposalState.NotCreated)
        )
    );
}


/// @title A proposal's configuration is immutable once set
rule configIsImmutable(method f, uint256 proposalId) {
    IVotingMachineWithProofs.ProposalVoteConfiguration preConf = (
        getProposalVoteConfiguration(proposalId)
    );

    env e;
    calldataarg args;
    f(e, args);

    IVotingMachineWithProofs.ProposalVoteConfiguration postConf = (
        getProposalVoteConfiguration(proposalId)
    );

    assert (
        (preConf.l1ProposalBlockHash != to_bytes32(0)) =>
        (preConf.l1ProposalBlockHash == postConf.l1ProposalBlockHash) &&
        (preConf.votingDuration == postConf.votingDuration)
    );
}


use rule method_reachability;
