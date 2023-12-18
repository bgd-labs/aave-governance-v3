/// ============================================================================
/// Vote Tally and Casting Votes
/// ============================================================================

/* Definitions
 * -----------
 * - Votes tally: The votes tally for a proposal is the pair (2-tuple) of votes in favor
 *   and votes against, i.e. `(forVotes, againstVotes)`.
 * - Stored voting power: The stored voting power of a voter `v` for a proposal `i` is
 *   the field `getUserProposalVote(v, i).votingPower`. 
 * - A vote was cast: We say that "a vote was cast" for a proposal `i` if there exists a
 *   voter `v` whose stored voting power for `i` changed from zero to positive.
 *
 * Summary
 * -------
 * This spec proves that in a single method call:
 * 1. The voting tally for proposal i changed if and only if a single voter cast a vote
 *    for proposal i
 * 2. At most one voter can cast a vote on one proposal
 * 3. When a vote is cast on a proposal, the proposal's votes tally changes accordingly
 * 4. The voting tally can be changed only using one of the voting methods
 *    (rule `onlyVoteCanChangeResult`)
 * 5. The voting tally in favor and against can only increase, and their sum equals
 *    the sum of stored voting powers for that proposal
 */

import "setup.spec";


// Ghosts and hooks ============================================================

/** @title Function indicating a vote was cast for the given proposal
 * A ghost function showing that `_proposals[proposalId].votes[voter].votingPower`
 * changed from zero to positive (see hook below).
 * @param proposalId
 * @return Whether a vote was cast for a given proposal
 */
ghost is_someoneVoting(uint256) returns bool;


/// @title The number of times values have been stored in voting map
ghost number_stores() returns mathint;


/** @title Ghost function following votes mapping
 * @param proposalID
 * @param voter
 * @return The registered voting power for the voter, namely the value of
 *  ` _proposals[proposalId].votes[voter].votingPower`, see invariant
 *  `votingPowerGhostIsVotingPower` below
 */
ghost storedVotingPower(uint256, address) returns uint248 {
    init_state axiom forall uint256 proposalId. forall address voter.
        storedVotingPower(proposalId, voter) == 0;
}


/// @title Sum of all (increasing) votes
ghost mapping(uint256 => mathint) votesSum {
    init_state axiom forall uint256 proposalId. votesSum[proposalId] == 0;
}


/** @title Hook updating the ghost functions
 * In particular, this hook implies that whenever `storedVotingPower(i, v)` changed from
 * zero to positive number then `is_someoneVoting(i)` must be true.
 */
hook Sstore 
    _proposals[KEY uint256 proposalId].votes[KEY address voter].votingPower
    uint248 newPower (uint248 oldPower) STORAGE
    {
        // Update `is_someoneVoting` - only the new
        havoc is_someoneVoting assuming (
            (oldPower == 0 && newPower > 0) => is_someoneVoting@new(proposalId)
        );

        // Update `number_stores`
        havoc number_stores assuming number_stores@new() == number_stores@old() + 1;

        // Update `storedVotingPower` - only the new power
        havoc storedVotingPower assuming (
            storedVotingPower@new(proposalId, voter) == newPower &&
            (
                forall uint256 pId. forall address v.
                (pId != proposalId || v != voter) =>
                storedVotingPower@new(pId, v) == storedVotingPower@old(pId, v)
            )
        );

        // Update `votesSum`
        votesSum[proposalId] = (
            newPower > oldPower ?
            votesSum[proposalId] + newPower - oldPower :
            votesSum[proposalId]
        );
    }


// Ghost voting power equivalence ==============================================

/// @title Utility function for `getUserProposalVote` invariant below
function getRegisteredVotingPower(uint256 proposalId, address voter) returns uint248 {
    IVotingMachineWithProofs.Vote vote = getUserProposalVote(voter, proposalId);
    return vote.votingPower;
}   


/** @title Stored voting power equals `getUserProposalVote`
 * This invariant proves that `storedVotingPower == getRegisteredVotingPower`.
 * It follows that if a vote is cast on proposal `i` then `is_someoneVoting(i)` is true.
 */
invariant votingPowerGhostIsVotingPower(uint256 proposalId, address voter)
    getRegisteredVotingPower(proposalId, voter) == storedVotingPower(proposalId, voter)
    filtered {
        f -> filteredMethods(f)
    }


// Votes tally =================================================================

/// @title A utility function for `sumOfVotes` invariant
function getVotesSum(uint256 proposalId) returns mathint {
    IVotingMachineWithProofs.ProposalWithoutVotes prop = getProposalById(proposalId);
    return prop.forVotes + prop.againstVotes;
}


/// @title The sum of votes in favor and against equals the sum of stored voting powers
invariant sumOfVotes(uint256 proposalId)
    votesSum[proposalId] == getVotesSum(proposalId)
    filtered {
        f -> filteredMethods(f)
    }


// Casting votes ===============================================================

/** @title If a proposal's votes tally changed then a vote was cast on the proposal
 * To be precise, if the proposal's votes tally changed then there exists a voter `v`
 * whose stored voting power on the proposal changed from zero to positive.
 */
rule voteTallyChangedOnlyByVoting(method f, uint256 proposalId) filtered {
    f -> filteredMethods(f)
} {
    assert sig:getProposalById(uint256).isView;

    IVotingMachineWithProofs.ProposalWithoutVotes pre = getProposalById(proposalId);
    mathint numStoresPre = number_stores();

    env e;
    calldataarg args;
    f(e, args);
    
    IVotingMachineWithProofs.ProposalWithoutVotes post = getProposalById(proposalId);

    mathint numStoresPost = number_stores();
    bool is_tallyChanged = (
        (pre.forVotes != post.forVotes) || (pre.againstVotes != post.againstVotes)
    );
    assert is_tallyChanged => (
        is_someoneVoting(proposalId) && (numStoresPost == numStoresPre + 1)
    );
}


/** @title Casting a vote changes the proposal's votes tally
 * If a vote was cast for a proposal, then the proposal's votes tally changed.
 * Moreover, the change in tally corresponds to the vote that was cast.
 */
rule voteUpdatesTally(method f, uint256 proposalId, address voter) filtered {
    f -> filteredMethods(f)
} {
    env e;
    IVotingMachineWithProofs.ProposalWithoutVotes pre = getProposalById(proposalId);
    IVotingMachineWithProofs.Vote preVote = getUserProposalVote(voter, proposalId);
    IVotingMachineWithProofs.ProposalState state = getProposalState(e, proposalId);

    calldataarg args;
    f(e, args);
    
    IVotingMachineWithProofs.ProposalWithoutVotes post = getProposalById(proposalId);
    IVotingMachineWithProofs.Vote postVote = getUserProposalVote(voter, proposalId);

    bool is_voteCast = (preVote.votingPower != postVote.votingPower);

    assert is_voteCast => (
        // hasn't voted before (also implies `postVote.votingPower > 0`)
        preVote.votingPower == 0 &&
        // Can't vote in a state other than `Active`
        state == IVotingMachineWithProofs.ProposalState.Active
    );

    mathint forChange = post.forVotes - pre.forVotes;
    mathint againstChange = post.againstVotes - pre.againstVotes;
    mathint votedPower = to_mathint(postVote.votingPower);
    assert (is_voteCast && postVote.support) => (
        (forChange == votedPower) && (againstChange == 0)
    );
    assert (is_voteCast && !postVote.support) => (
        (forChange == 0) && (againstChange == votedPower)
    );
}


/** @title Returns true if `f` is a voting method where sender is the voter
 *  Used in `dispatchVote` and `onlyVoteCanChangeResult` below.
 */
function isSenderVoterFunction(method f) returns bool {
    return (
        f.selector == sig:submitVote(
            uint256, bool, IVotingMachineWithProofs.VotingBalanceProof[]
        ).selector || f.selector == sig:submitVoteSingleProof(
            uint256, bool, IVotingMachineWithProofs.VotingBalanceProof
        ).selector    
    );
}


/** @title Utility function for dispatching voting methods - ensures correct voter
 *  Used in `onlyVoteCanChangeResult` and `strangerVoteUnchanged` below.
 */
function dispatchVote(method f, env e, address voter) {
    // Commonly used args
    uint256 aProposalId;
    bool support;
    IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs;

    if (f.selector == sig:submitVoteAsRepresentative(
            uint256,bool,address,bytes,IVotingMachineWithProofs.VotingBalanceProof[]
        ).selector
    ) {
        bytes proofOfRepresentation;
        submitVoteAsRepresentative(
            e, aProposalId, support, voter, proofOfRepresentation, votingBalanceProofs
        );
    } else if (f.selector == sig:submitVoteAsRepresentativeBySignature(
            uint256,address,address,bool,bytes,
            IVotingMachineWithProofs.VotingBalanceProof[],
            IVotingMachineWithProofs.SignatureParams
        ).selector
    ) {
        address representative;
        bytes proofOfRepresentation;
        IVotingMachineWithProofs.SignatureParams signatureParams;
        submitVoteAsRepresentativeBySignature(
            e, aProposalId, voter, representative, support, proofOfRepresentation,
            votingBalanceProofs,
            signatureParams
        );
    } else if (f.selector == sig:submitVoteBySignature(
            uint256, address, bool, IVotingMachineWithProofs.VotingBalanceProof[],
            uint8, bytes32, bytes32
        ).selector
    ) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        submitVoteBySignature(e, aProposalId, voter, support, votingBalanceProofs, v, r, s);
    } else if (f.selector == sig:submitVoteFromVoter(
            address, uint256, bool, IVotingMachineWithProofs.VotingBalanceProof[]
        ).selector
    ) {
        submitVoteFromVoter(e, voter, aProposalId, support, votingBalanceProofs);
    } else {
        if isSenderVoterFunction(f) {
            // The sender is the voter
            require voter == e.msg.sender;
        }
        calldataarg args;
        f(e, args);
    }
}


/// @title Vote tally can be changed only by one of the voting methods
rule onlyVoteCanChangeResult(method f, uint256 proposalId, address voter) filtered {
    f -> filteredMethods(f)
} {
    env e;
    IVotingMachineWithProofs.ProposalWithoutVotes pre = getProposalById(proposalId);
    IVotingMachineWithProofs.Vote preVote = getUserProposalVote(voter, proposalId);

    dispatchVote(f, e, voter);

    IVotingMachineWithProofs.ProposalWithoutVotes post = getProposalById(proposalId);
    IVotingMachineWithProofs.Vote postVote = getUserProposalVote(voter, proposalId);
    
    bool is_tallyChanged = (
        (pre.forVotes != post.forVotes) || (pre.againstVotes != post.againstVotes)
    );
    // Is the `voter` the one who cast the vote
    bool is_voterCastVote = preVote.votingPower != postVote.votingPower;

    assert (
        is_tallyChanged => is_voterCastVote && (
            isSenderVoterFunction(f) ||
            f.selector == sig:submitVoteAsRepresentative(
                uint256,bool,address,bytes,IVotingMachineWithProofs.VotingBalanceProof[]
            ).selector ||
            f.selector == sig:submitVoteAsRepresentativeBySignature(
                uint256,address,address,bool,bytes,
                IVotingMachineWithProofs.VotingBalanceProof[],
                IVotingMachineWithProofs.SignatureParams
            ).selector ||
            f.selector == sig:submitVoteBySignature(
                uint256, address, bool, IVotingMachineWithProofs.VotingBalanceProof[],
                uint8, bytes32, bytes32
            ).selector ||
            f.selector == sig:submitVoteFromVoter(
                address, uint256, bool, IVotingMachineWithProofs.VotingBalanceProof[]
            ).selector
        )
    );
}


/// @title Voting tally can only increase
rule votingTallyCanOnlyIncrease(method f, uint256 proposalId) filtered {
    f -> filteredMethods(f)
} {
    IVotingMachineWithProofs.ProposalWithoutVotes pre = getProposalById(proposalId);

    env e;
    calldataarg args;
    f(e, args);

    IVotingMachineWithProofs.ProposalWithoutVotes post = getProposalById(proposalId);
    
    bool is_tallyChanged = (
        (pre.forVotes != post.forVotes) || (pre.againstVotes != post.againstVotes)
    );
    assert is_tallyChanged => (
        (post.forVotes > pre.forVotes) || (post.againstVotes > pre.againstVotes)
    );
    assert (post.forVotes >= pre.forVotes) && (post.againstVotes >= pre.againstVotes);
}


// Other proposals and voters ==================================================

/// @title A stranger's stored vote is unchanged when another votes
rule strangerVoteUnchanged(method f, uint256 proposalId, address stranger, address voter) 
filtered {
    f -> filteredMethods(f)
} {
    require voter != stranger;
    IVotingMachineWithProofs.Vote strangePre = getUserProposalVote(stranger, proposalId);

    env e;
    dispatchVote(f, e, voter);

    IVotingMachineWithProofs.Vote strangePost = getUserProposalVote(stranger, proposalId);

    assert strangePre.support == strangePost.support;
    assert strangePre.votingPower == strangePost.votingPower;
}


/// @title Only a single proposal's tally and votes may change by a single method call
rule otherProposalUnchanged(
    method f, uint256 proposalId, uint256 otherProposal, address otherVoter
) filtered {
    f -> filteredMethods(f)
} {
    require proposalId != otherProposal;

    env e;
    IVotingMachineWithProofs.ProposalWithoutVotes preOriginal = getProposalById(proposalId);
    IVotingMachineWithProofs.ProposalWithoutVotes preOther = getProposalById(otherProposal);
    IVotingMachineWithProofs.Vote preOVote = getUserProposalVote(otherVoter, otherProposal);

    calldataarg args;
    f(e, args);
    
    IVotingMachineWithProofs.ProposalWithoutVotes postOriginal = getProposalById(proposalId);
    IVotingMachineWithProofs.ProposalWithoutVotes postOther = getProposalById(otherProposal);
    IVotingMachineWithProofs.Vote postOVote = getUserProposalVote(otherVoter, otherProposal);

    bool is_tallyChanged = (
        (preOriginal.forVotes != postOriginal.forVotes) ||
        (preOriginal.againstVotes != postOriginal.againstVotes)
    );
    bool is_otherTallyChanged = (
        (preOther.forVotes != postOther.forVotes) ||
        (preOther.againstVotes != postOther.againstVotes)
    );
    bool is_otherVoteChanged = (preOVote.votingPower != postOVote.votingPower);
    assert is_tallyChanged => (!is_otherTallyChanged && !is_otherVoteChanged);
}


/// @title Only a single voter's stored voting power may change (on a given proposal)
rule otherVoterUntouched(
    method f, uint256 proposalId, address voter, address stranger
) filtered {
    f -> filteredMethods(f)
} {
    require voter != stranger;

    env e;
    IVotingMachineWithProofs.Vote preVoter = getUserProposalVote(voter, proposalId);
    IVotingMachineWithProofs.Vote preStranger = getUserProposalVote(stranger, proposalId);

    calldataarg args;
    f(e, args);
    
    IVotingMachineWithProofs.Vote postVoter = getUserProposalVote(voter, proposalId);
    IVotingMachineWithProofs.Vote postStranger = getUserProposalVote(stranger, proposalId);

    bool is_voterChanged = (preVoter.votingPower != postVoter.votingPower);
    bool is_strangerChanged = (preStranger.votingPower != postStranger.votingPower);
    assert is_voterChanged => !is_strangerChanged;
}

// rule sanity{
//   env e;
//   calldataarg arg;
//   method f;
//   f(e, arg);
//   satisfy true;
// }

// // Representative
// rule cannot_vote_twice_with_submitVote(method f) filtered { f -> !f.isView}{
    
//     env e1;
//     env e2;
//     uint256 proposalId1;
//     uint256 proposalId2;
//     bool support1;
//     bool support2;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs1;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;
//     env e_f;
//     calldataarg args;
    
//     submitVote(e1, proposalId1,support1,votingBalanceProofs1);
//     f(e_f, args);
//     submitVote(e2, proposalId2,support2,votingBalanceProofs2);
//     assert  proposalId1 == proposalId2 => e1.msg.sender != e2.msg.sender;

// }


// rule cannot_vote_twice_with_submitVote_witness{
    
//     env e1;
//     env e2;
//     uint256 proposalId1;
//     uint256 proposalId2;
//     bool support1;
//     bool support2;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs1;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;

//     submitVote(e1, proposalId1,support1,votingBalanceProofs1);
//     submitVote(e2, proposalId2,support2,votingBalanceProofs2);
//     require proposalId1 == proposalId2;
//     satisfy e1.msg.sender != e2.msg.sender;
// }


//check  submitVoteAsRepresentative and submitVote

rule cannot_vote_twice_with_submitVote_and_submitVoteAsRepresentative(method f) filtered {
    f -> filteredMethods(f) && !f.isView
} {
    
    env e1;
    env e2;
    uint256 proposalId1;
    uint256 proposalId2;
    bool support1;
    bool support2;
    IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs1;
    IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;
    address voter;
    bytes proofOfRepresentation;

    env e_f;
    calldataarg args;
    
    submitVote(e1, proposalId1,support1,votingBalanceProofs1);
    f(e_f, args);
    submitVoteAsRepresentative(e2, proposalId2, support2, voter, proofOfRepresentation, votingBalanceProofs2);
    
    assert  proposalId1 == proposalId2 => e1.msg.sender != voter;

}

// rule cannot_vote_twice_with_submitVote_and_submitVoteAsRepresentative_witness(method f) filtered { f -> !f.isView}{
    
//     env e1;
//     env e2;
//     uint256 proposalId1;
//     uint256 proposalId2;
//     bool support1;
//     bool support2;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs1;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;
//     address voter;
//     bytes proofOfRepresentation;

//     env e_f;
//     calldataarg args;
    
//     submitVote(e1, proposalId1,support1,votingBalanceProofs1);
//     f(e_f, args);
//     submitVoteAsRepresentative(e2, proposalId2, support2, voter, proofOfRepresentation, votingBalanceProofs2);
    
//     require proposalId1 == proposalId2;
//     satisfy e1.msg.sender != voter;

// }


rule cannot_vote_twice_with_submitVoteAsRepresentative_and_submitVote(method f) filtered {
    f -> filteredMethods(f) && !f.isView
} {
  
    env e1;
    env e2;
    uint256 proposalId1;
    uint256 proposalId2;
    bool support1;
    bool support2;
    IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs1;
    IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;
    address voter;
    bytes proofOfRepresentation;

    env e_f;
    calldataarg args;
    
    submitVoteAsRepresentative(e2, proposalId2, support2, voter, proofOfRepresentation, votingBalanceProofs2);
    f(e_f, args);
    submitVote(e1, proposalId1,support1,votingBalanceProofs1);
    
    assert  proposalId1 == proposalId2 => e1.msg.sender != voter;

}

// rule cannot_vote_twice_with_submitVoteAsRepresentative_and_submitVote_witness(method f) filtered { f -> !f.isView}{
    
//     env e1;
//     env e2;
//     uint256 proposalId1;
//     uint256 proposalId2;
//     bool support1;
//     bool support2;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs1;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;
//     address voter;
//     bytes proofOfRepresentation;

//     env e_f;
//     calldataarg args;
    
//     submitVoteAsRepresentative(e2, proposalId2, support2, voter, proofOfRepresentation, votingBalanceProofs2);
//     f(e_f, args);
//     submitVote(e1, proposalId1,support1,votingBalanceProofs1);
    
//     require proposalId1 == proposalId2;
//     satisfy e1.msg.sender != voter;

// }

//check  submitVoteAsRepresentative and submitVoteSingleProof


//   rule cannot_vote_twice_with_submitVoteSingleProof_and_submitVoteAsRepresentative(method f) filtered { f -> !f.isView}{
    
//     env e1;
//     env e2;
//     uint256 proposalId1;
//     uint256 proposalId2;
//     bool support1;
//     bool support2;
//     IVotingMachineWithProofs.VotingBalanceProof votingBalanceProofs1;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;
//     address voter;
//     bytes proofOfRepresentation;

//     env e_f;
//     calldataarg args;
    
//     submitVoteSingleProof(e1, proposalId1,support1,votingBalanceProofs1);
//     f(e_f, args);
//     submitVoteAsRepresentative(e2, proposalId2, support2, voter, proofOfRepresentation, votingBalanceProofs2);
    
//     assert  proposalId1 == proposalId2 => e1.msg.sender != voter;

// }

// rule cannot_vote_twice_with_submitVoteSingleProof_and_submitVoteAsRepresentative_witness(method f) filtered { f -> !f.isView}{
    
//     env e1;
//     env e2;
//     uint256 proposalId1;
//     uint256 proposalId2;
//     bool support1;
//     bool support2;
//     IVotingMachineWithProofs.VotingBalanceProof votingBalanceProofs1;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;
//     address voter;
//     bytes proofOfRepresentation;

//     env e_f;
//     calldataarg args;
    
//     submitVoteSingleProof(e1, proposalId1,support1,votingBalanceProofs1);
//     f(e_f, args);
//     submitVoteAsRepresentative(e2, proposalId2, support2, voter, proofOfRepresentation, votingBalanceProofs2);
    
//     require proposalId1 == proposalId2;
//     satisfy e1.msg.sender != voter;

// }


rule cannot_vote_twice_with_submitVoteSingleProofAsRepresentative_and_submitVote(method f)
filtered {
    f -> filteredMethods(f) && !f.isView
} {
    
    env e1;
    env e2;
    uint256 proposalId1;
    uint256 proposalId2;
    bool support1;
    bool support2;
    IVotingMachineWithProofs.VotingBalanceProof votingBalanceProofs1;
    IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;
    address voter;
    bytes proofOfRepresentation;

    env e_f;
    calldataarg args;
    
    submitVoteAsRepresentative(e2, proposalId2, support2, voter, proofOfRepresentation, votingBalanceProofs2);
    f(e_f, args);
    submitVoteSingleProof(e1, proposalId1,support1,votingBalanceProofs1);
    
    assert  proposalId1 == proposalId2 => e1.msg.sender != voter;

}

// rule cannot_vote_twice_with_submitVoteAsRepresentative_and_submitVoteSingleProof_witness(method f) filtered { f -> !f.isView}{
    
//     env e1;
//     env e2;
//     uint256 proposalId1;
//     uint256 proposalId2;
//     bool support1;
//     bool support2;
//     IVotingMachineWithProofs.VotingBalanceProof votingBalanceProofs1;
//     IVotingMachineWithProofs.VotingBalanceProof[] votingBalanceProofs2;
//     address voter;
//     bytes proofOfRepresentation;

//     env e_f;
//     calldataarg args;
    
//     submitVoteAsRepresentative(e2, proposalId2, support2, voter, proofOfRepresentation, votingBalanceProofs2);
//     f(e_f, args);
//     submitVoteSingleProof(e1, proposalId1,support1,votingBalanceProofs1);
    
//     require proposalId1 == proposalId2;
//     satisfy e1.msg.sender != voter;

// }



// setup self check - reachability of currentContract and external functions
rule method_reachability(method f) filtered {
    f -> filteredMethods(f)
} {
  env e;
  calldataarg arg;
  f(e, arg);
  satisfy true;
}
