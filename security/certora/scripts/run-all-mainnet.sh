#CMN="--compilation_steps_only"



echo "******** Running:  mainnet 1 ***************"
certoraRun $CMN security/certora/confs/verifyVotingStrategy_unittests.conf \
           --msg "mainnet 1 "
           
echo "******** Running:  mainnet 2 ***************"
certoraRun $CMN security/certora/confs/verifyGovernancePowerStrategy.conf --rule delegatePowerCompliance  \
           --msg "mainnet 2 "

           
echo "******** Running:  mainnet 3 ***************"
certoraRun $CMN security/certora/confs/verifyGovernancePowerStrategy.conf --rule transferPowerCompliance \
           --msg "mainnet 3 "


echo "******** Running:  mainnet 4 ***************"
certoraRun $CMN security/certora/confs/verifyGovernancePowerStrategy.conf --rule powerlessCompliance method_reachability \
           --msg "mainnet 4 "


echo "******** Running:  mainnet 5 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule cancellationFeeZeroForFutureProposals null_state_variable_iff_null_access_level zero_voting_portal_iff_uninitialized_proposal \
           --msg "mainnet 5 "


echo "******** Running:  mainnet 6 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule no_self_representative no_representative_is_zero consecutiveIDs totalCancellationFeeEqualETHBalance zero_address_is_not_a_valid_voting_portal \
           --msg "mainnet 6 "


echo "******** Running:  mainnet 7 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule no_representative_is_zero_2 no_representative_of_zero \
           --msg "mainnet 7 "


echo "******** Running:  mainnet 8 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule state_changing_function_self_check state_variable_changing_function_self_check method_reachability userFeeDidntChangeImplyNativeBalanceDidntDecrease \
           --msg "mainnet 8 "


echo "******** Running:  mainnet 9 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule check_new_representative_set_size_after_updateRepresentatives check_old_representative_set_size_after_updateRepresentatives \
           --msg "mainnet 9 "


echo "******** Running:  mainnet 10 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule at_least_single_payload_active empty_payloads_iff_uninitialized_proposal \
           --msg "mainnet 10 "


echo "******** Running:  mainnet 11 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule null_state_iff_uninitialized_proposal setInvariant addressSetInvariant \
           --msg "mainnet 11 "


echo "******** Running:  mainnet 12 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule state_changing_function_cannot_be_called_while_in_terminal_state proposal_executes_after_cooldown_period \
           --msg "mainnet 12 "


echo "******** Running:  mainnet 13 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule only_valid_voting_portal_can_queue_proposal immutable_after_activation immutable_after_creation only_guardian_can_cancel guardian_can_cancel \
           --msg "mainnet 13 "


echo "******** Running:  mainnet 14 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule cannot_queue_when_voting_portal_unapproved only_owner_can_set_voting_config_witness only_owner_can_set_voting_config single_state_transition_per_block_non_creator_witness \
           --msg "mainnet 14 "


echo "******** Running:  mainnet 15 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule single_state_transition_per_block_non_creator_non_guardian state_cant_decrease no_state_transitions_beyond_3 immutable_voting_portal \
           --msg "mainnet 15 "


echo "******** Running:  mainnet 16 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule proposal_after_voting_portal_invalidate insufficient_proposition_power insufficient_proposition_power_witness_state_is_failed insufficient_proposition_power_witness_state_is_cancelled insufficient_proposition_power_witness_time_elapsed \
           --msg "mainnet 16 "


echo "******** Running:  mainnet 17 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule creator_is_not_zero creator_of_initialized_proposal_is_not_zero null_state_equivalence \
           --msg "mainnet 17 "


echo "******** Running:  mainnet 18 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule insufficient_proposition_power_witness_time_elapsed \
           --msg "mainnet 18 "


echo "******** Running:  mainnet 19 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule immutable_after_creation_witness_creator immutable_after_creation_witness_voting_portal \
           --msg "mainnet 19 "


echo "******** Running:  mainnet 20 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule immutable_after_creation_witness_access_level immutable_after_creation_witness_creation_time immutable_after_creation_witness_ipfs_hash \
           --msg "mainnet 20 "


echo "******** Running:  mainnet 21 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule immutable_after_creation_witness_payload_length immutable_after_activation_witness only_state_changing_function_initiate_transitions__pre_state \
           --msg "mainnet 21 "


echo "******** Running:  mainnet 22 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule only_state_changing_function_initiate_transitions__post_state \
           --msg "mainnet 22 "


echo "******** Running:  mainnet 23 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule check_new_representative_set_size_after_updateRepresentatives_witness_antecedent_first check_new_representative_set_size_after_updateRepresentatives_witness_antecedent_second check_new_representative_set_size_after_updateRepresentatives_witness_consequent_first check_new_representative_set_size_after_updateRepresentatives_witness_consequent_second \
           --msg "mainnet 23 "


echo "******** Running:  mainnet 24 ***************"
certoraRun $CMN security/certora/confs/verifyGovernance.conf --rule proposal_voting_duration_lt_expiration_time config_voting_duration_lt_expiration_time proposal_state_transition_post_state proposal_state_transition_pre_state \
           --msg "mainnet 24 "

