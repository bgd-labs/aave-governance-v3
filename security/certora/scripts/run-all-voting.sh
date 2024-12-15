CMN="--compilation_steps_only"



echo "******** Running:  voting:1 ***************"
certoraRun $CMN security/certora/confs/voting/verifyLegality.conf \
            --rule createdVoteHasNonZeroHash  votedPowerIsImmutable  onlyValidProposalCanChangeTally  legalVote  method_reachability \
           --msg "voting 1: "
           

echo "******** Running:  voting:2  ***************"
certoraRun $CMN security/certora/confs/voting/verifyMisc.conf \
            \
           --msg "voting 2: "


echo "******** Running:  voting:3  ***************"
certoraRun $CMN security/certora/confs/voting/verifyPower_summary.conf \
            --rule onlyThreeTokens method_reachability \
           --msg "voting 3: "



echo "******** Running:  voting:4  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_config.conf \
            --rule startedProposalHasConfig  createdProposalHasRoots  proposalHasNonzeroDuration newProposalUnusedId configIsImmutable  getProposalsConfigsDoesntRevert  method_reachability \
           --msg "voting 4: "
           


echo "******** Running:  voting:5  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
            --rule startsBeforeEnds  startsStrictlyBeforeEnds  proposalLegalStates  proposalMethodStateTransitionCompliance  proposalTimeStateTransitionCompliance  proposalIdIsImmutable  proposalImmutability  startedProposalHasConfig  proposalHasNonzeroDuration method_reachability \
           --msg "voting 5: "



echo "******** Running:  voting:6  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
            --rule votingPowerGhostIsVotingPower  sumOfVotes  voteTallyChangedOnlyByVoting  voteUpdatesTally  onlyVoteCanChangeResult  votingTallyCanOnlyIncrease  strangerVoteUnchanged  otherProposalUnchanged  otherVoterUntouched  method_reachability \
           --msg "voting 6: "


echo "******** Running:  voting:7  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
            --rule cannot_vote_twice_with_submitVote_and_submitVoteAsRepresentative \
           --msg "voting 7: "


echo "******** Running:  voting:8  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
            --rule cannot_vote_twice_with_submitVoteAsRepresentative_and_submitVote \
