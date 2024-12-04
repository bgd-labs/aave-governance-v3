#CMN="--compilation_steps_only"



echo "******** Running:  voting:1 ***************"
certoraRun $CMN security/certora/confs/voting/verifyLegality.conf \
           --rule createdVoteHasNonZeroHash \
           --msg "voting 1: "
           
echo "******** Running:  voting:2  ***************"
certoraRun $CMN security/certora/confs/voting/verifyLegality.conf \
           --rule votedPowerIsImmutable \
           --msg "voting 2: "

echo "******** Running:  voting:3 ***************"
certoraRun $CMN security/certora/confs/voting/verifyLegality.conf \
           --rule onlyValidProposalCanChangeTally \
           --msg "voting 3: "


echo "******** Running:  voting:4  ***************"
certoraRun $CMN security/certora/confs/voting/verifyLegality.conf \
           --rule legalVote \
           --msg "voting 4: "


echo "******** Running:  voting:5  ***************"
certoraRun $CMN security/certora/confs/voting/verifyLegality.conf \
           --rule method_reachability \
           --msg "voting 5: "


echo "******** Running:  voting:6  ***************"
certoraRun $CMN security/certora/confs/voting/verifyMisc.conf \
           --msg "voting 6: "


#TODO: uncomment with certora-cli version 6.0 or higher
echo "******** Running:  voting:7  ***************"
certoraRun $CMN security/certora/confs/voting/verifyPower_summary.conf \
           --rule onlyThreeTokens \
           --msg "voting 7: "

echo "******** Running:  voting:8  ***************"
certoraRun $CMN security/certora/confs/voting/verifyPower_summary.conf \
           --rule method_reachability \
           --msg "voting 8: "


echo "******** Running:  voting:9  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_config.conf \
           --rule startedProposalHasConfig \
           --msg "voting 9: "
           
echo "******** Running:  voting:10  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_config.conf \
           --rule createdProposalHasRoots \
           --msg "voting 10: "


echo "******** Running:  voting:11  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_config.conf \
           --rule proposalHasNonzeroDuration newProposalUnusedId configIsImmutable \
           --msg "voting 11: "


echo "******** Running:  voting:12  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_config.conf \
           --rule getProposalsConfigsDoesntRevert \
           --msg "voting 12: "


echo "******** Running:  voting:13  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_config.conf \
           --rule method_reachability \
           --msg "voting 13: "


echo "******** Running:  voting:14  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
           --rule startsBeforeEnds \
           --msg "voting 14: "


echo "******** Running:  voting:15  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
           --rule startsStrictlyBeforeEnds \
           --msg "voting 15: "


echo "******** Running:  voting:16  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
           --rule proposalLegalStates \
           --msg "voting 16: "


echo "******** Running:  voting:17  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
           --rule proposalMethodStateTransitionCompliance \
           --msg "voting 17: "


echo "******** Running:  voting:18  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
           --rule proposalTimeStateTransitionCompliance \
           --msg "voting 18: "


echo "******** Running:  voting:19  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
           --rule proposalIdIsImmutable \
           --msg "voting 19: "


echo "******** Running:  voting:20  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
           --rule proposalImmutability \
           --msg "voting 20: "


echo "******** Running:  voting:21  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
           --rule startedProposalHasConfig \
           --msg "voting 21: "


echo "******** Running:  voting:22  ***************"
certoraRun $CMN security/certora/confs/voting/verifyProposal_states.conf \
           --rule proposalHasNonzeroDuration method_reachability \
           --msg "voting 22: "


echo "******** Running:  voting:23  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule votingPowerGhostIsVotingPower \
           --msg "voting 23: "


echo "******** Running:  voting:24  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule sumOfVotes \
           --msg "voting 24: "


echo "******** Running:  voting:25  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule voteTallyChangedOnlyByVoting \
           --msg "voting 25: "


echo "******** Running:  voting:26  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule voteUpdatesTally \
           --msg "voting 26: "


echo "******** Running:  voting:27  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule onlyVoteCanChangeResult \
           --msg "voting 27: "


echo "******** Running:  voting:28  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule votingTallyCanOnlyIncrease \
           --msg "voting 28: "


echo "******** Running:  voting:29  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule strangerVoteUnchanged \
           --msg "voting 29: "


echo "******** Running:  voting:30  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule otherProposalUnchanged \
           --msg "voting 30: "


echo "******** Running:  voting:31  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule otherVoterUntouched \
           --msg "voting 31: "


echo "******** Running:  voting:32  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule cannot_vote_twice_with_submitVote_and_submitVoteAsRepresentative \
           --msg "voting 32: "


echo "******** Running:  voting:33  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule cannot_vote_twice_with_submitVoteAsRepresentative_and_submitVote \
           --msg "voting 33: "


echo "******** Running:  voting:34  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule cannot_vote_twice_with_submitVoteSingleProofAsRepresentative_and_submitVote \
           --msg "voting 34: "


echo "******** Running:  voting:35  ***************"
certoraRun $CMN security/certora/confs/voting/verifyVoting_and_tally.conf \
           --rule method_reachability \
           --msg "voting 35: "

