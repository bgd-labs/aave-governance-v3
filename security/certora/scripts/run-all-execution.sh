#CMN="--compilation_steps_only"



           
echo "******** Running:  execution 0 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule payload_maximal_access_level_gt_action_access_level state_cant_decrease no_transition_beyond_state_gt_3 no_transition_beyond_state_variable_gt_3 no_queue_after_expiration empty_actions_if_out_of_bound_payload expirationTime_equal_to_createAt_plus_EXPIRATION_DELAY empty_actions_iff_uninitialized null_access_level_if_out_of_bound_payload null_creator_and_zero_expiration_time_if_out_of_bound_payload empty_actions_only_if_uninitialized_payload executor_access_level_within_range consecutiveIDs empty_actions_if_uninitialized_payload queued_before_expiration_delay payload_grace_period_eq_global_grace_period null_access_level_only_if_out_of_bound_payload null_state_variable_if_out_of_bound_payload created_in_the_past queued_after_created executed_after_queue queuedAt_is_zero_before_queued no_early_cancellation execute_before_delay__maximumAccessLevelRequired action_immutable_fixed_size_fields initialized_payload_fields_are_immutable payload_fields_immutable_after_createPayload method_reachability \
           --msg "execution 0 "



echo "******** Running:  execution 1 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executor_exists_if_action_not_null \
           --msg "execution 1 "


echo "******** Running:  execution 2 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executor_exists_only_if_action_not_null \
           --msg "execution 2 "


echo "******** Running:  execution 3 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule payload_delay_within_range \
           --msg "execution 3 "


echo "******** Running:  execution 4 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule delay_of_executor_of_max_access_level_within_range \
           --msg "execution 4 "


echo "******** Running:  execution 5 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule nonempty_actions \
           --msg "execution 5 "


echo "******** Running:  execution 6 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executor_exists_iff_action_not_null \
           --msg "execution 6 "


echo "******** Running:  execution 7 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule null_access_level_iff_state_is_none \
           --msg "execution 7"


echo "******** Running:  execution 8 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executor_of_maximumAccessLevelRequired_exists \
           --msg "execution 8 "


echo "******** Running:  execution 9 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executor_of_maximumAccessLevelRequired_exists_after_createPayload \
           --msg "execution 9 "


echo "******** Running:  execution 10 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule action_access_level_isnt_null_after_createPayload \
           --msg "execution 10 "


echo "******** Running:  execution 11 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executor_exists_after_createPayload \
           --msg "execution 11 "


echo "******** Running:  execution 12 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule action_callData_immutable \
           --msg "execution 12 "


echo "******** Running:  execution 13 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule action_signature_immutable \
           --msg "execution 13 "


echo "******** Running:  execution 14 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule action_immutable_check_only_fixed_size_fields \
           --msg "execution 14 "


echo "******** Running:  execution 15 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule zero_executedAt_if_not_executed \
           --msg "execution 15 "


echo "******** Running:  execution16: ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executor_isnt_used_twice executor_of_level_null_is_zero \
           --msg "execution 16 "

echo "******** Running:  execution 17 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executed_after_queue_state_variable zero_executedAt_if_not_executed_state_variable \
           --msg "execution 17 "


echo "******** Running:  execution 18 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule queuedAt_is_zero_before_queued_state_variable executedAt_is_zero_before_executed_state_variable null_state_equivalence \
           --msg "execution 18 "


echo "******** Running:  execution 19 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executedAt_is_zero_before_executed \
           --msg "execution 19 "


echo "******** Running:  execution 20 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executed_when_in_queued_state executed_when_in_queued_state_variable guardian_can_cancel no_late_cancel state_variable_cant_decrease \
           --msg "execution 20 "


echo "******** Running:  execution 21 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule checkUpdateExecutors checkUpdateExecutors_witness_1 checkUpdateExecutors_witness_2 checkUpdateExecutors_witness_3 checkUpdateExecutors_witness_4 \
           --msg "execution 21 "


echo "******** Running:  execution 22 ***************"
certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule payload_state_transition_post_state payload_state_transition_pre_state \
           --msg "execution 22 "


#  certoraRun $CMN security/certora/confs/payloads/verifyPayloadsController.conf --rule executor_exists














          
