

methods {

	//Summarization 
	// executes a transaction
	function _.executeTransaction(address,uint256,string,bytes,bool) external  => NONDET;
	function _.transfer(address,uint256) external => DISPATCHER(true);

	//Envfree methods
	function getActionsLength(uint40) external returns (uint256) envfree;
	function getPayloadsCount() external returns (uint40) envfree;
	function getMaximumAccessLevelRequired(uint40) external returns (PayloadsControllerUtils.AccessControl) envfree;
	function getActionFixedSizeFields(uint40,uint256) external returns (address,bool,PayloadsControllerUtils.AccessControl,uint256) envfree;
	function getAction(uint40,uint256) external returns (IPayloadsControllerCore.ExecutionAction) envfree;
	function getActionAccessLevel(uint40, uint256) external returns (PayloadsControllerUtils.AccessControl) envfree;
	function getActionSignature(uint40,uint256) external returns (string) envfree;
	function getActionCallData(uint40,uint256) external returns (bytes) envfree;
	function compare(string,string) external returns (bool) envfree;
	function compare(bytes,bytes) external returns (bool) envfree;
	function getExecutorSettingsByAccessControl(PayloadsControllerUtils.AccessControl) external returns (IPayloadsControllerCore.ExecutorConfig) envfree;
	function getPayloadById(uint40) external returns (IPayloadsControllerCore.Payload);
	function getPayloadFieldsById(uint40 payloadId) external 
  		returns (address,PayloadsControllerUtils.AccessControl,IPayloadsControllerCore.PayloadState,uint40,uint40,uint40,uint40,uint40,uint40,uint40) envfree;
	function getPayloadGracePeriod(uint40 payloadId) external returns (uint40) envfree;
	function getPayloadDelay(uint40 payloadId) external returns (uint40) envfree;
	function getPayloadCreatedAt(uint40 payloadId) external returns (uint40) envfree;
	function getPayloadQueuedAt(uint40 payloadId) external returns (uint40) envfree;
	function getPayloadExecutedAt(uint40 payloadId) external returns (uint40) envfree;
	

	function getPayloadStateVariable(uint40) external returns (IPayloadsControllerCore.PayloadState) envfree;
	function getCreator(uint40) external returns (address) envfree;
	function getExpirationTime(uint40) external returns (uint40) envfree;
	function decodeMessage(bytes) external returns (uint40, PayloadsControllerUtils.AccessControl, uint40) envfree;
	function encodeMessage(uint40,PayloadsControllerUtils.AccessControl,uint40) external returns (bytes) envfree;

	function GRACE_PERIOD() external returns (uint40) envfree;
	function MIN_EXECUTION_DELAY() external returns (uint40) envfree;
	function MAX_EXECUTION_DELAY() external returns (uint40) envfree;
	function EXPIRATION_DELAY() external returns (uint40) envfree;
	function guardian() external returns (address) envfree;
  	function owner() external returns (address) envfree;
}

//
// CVL Functions extracting struct fields
//
function get_action_executor(uint40 payloadID, uint256 actionID) returns address{
	IPayloadsControllerCore.ExecutorConfig executorCfg = getExecutorSettingsByAccessControl(getActionAccessLevel(payloadID, actionID));
	return executorCfg.executor;
}
function get_executor_of_maximumAccessLevelRequired(uint40 id) returns address{
	IPayloadsControllerCore.ExecutorConfig executorCfg = getExecutorSettingsByAccessControl(getMaximumAccessLevelRequired(id));
	return executorCfg.executor;
}

function get_delay_of_maximumAccessLevelRequired(uint40 id) returns uint40{
	PayloadsControllerUtils.AccessControl maximumAccessLevelRequired = getMaximumAccessLevelRequired(id);
	IPayloadsControllerCore.ExecutorConfig executorCfg = getExecutorSettingsByAccessControl(maximumAccessLevelRequired);
	return executorCfg.delay;
}

function get_executor(PayloadsControllerUtils.AccessControl access_level) returns address{
	IPayloadsControllerCore.ExecutorConfig executorCfg = getExecutorSettingsByAccessControl(access_level);
	return executorCfg.executor;
}
function get_delay(PayloadsControllerUtils.AccessControl access_level) returns uint40{
	IPayloadsControllerCore.ExecutorConfig executorCfg = getExecutorSettingsByAccessControl(access_level);
	return executorCfg.delay;
}

//
// Helpers
//

//
// Payloads
//
// General: a payload is uninitialized and has no actions unless it was added to _payloads mapping

/// @title A payload has no actions if it's beyond _payloadsCount
invariant  empty_actions_if_out_of_bound_payload(uint40 id)
	id >= getPayloadsCount() => getActionsLength(id) == 0;


/// @title Payload state is None if the payload is beyond _payloadsCount
invariant  null_state_variable_if_out_of_bound_payload(uint40 id)
	id >= getPayloadsCount() => getPayloadStateVariable(id) == IPayloadsControllerCore.PayloadState.None;

/// @title Payload maximal access level is null (not valid) if the payload is beyond _payloadsCount
invariant  null_access_level_if_out_of_bound_payload(uint40 id)
	id >= getPayloadsCount() => getMaximumAccessLevelRequired(id) == PayloadsControllerUtils.AccessControl.Level_null;

/// @title Payload creator is address(0) and it expiration time is zero if the payload is beyond _payloadsCount
invariant  null_creator_and_zero_expiration_time_if_out_of_bound_payload(uint40 id)
	id >= getPayloadsCount() => 
	getCreator(id) == 0 && getExpirationTime(id) == 0
	&& getPayloadGracePeriod(id) == 0 && getPayloadDelay(id) == 0;

/// @title Payload's maximal access level is null if and only if state is none 
invariant  null_access_level_iff_state_is_none(uint40 id)
	getMaximumAccessLevelRequired(id) == PayloadsControllerUtils.AccessControl.Level_null <=>
	getPayloadStateVariable(id) == IPayloadsControllerCore.PayloadState.None;



//
// Actions
//

/// @title accessLevel of a valid action is not null
/// @dev a helper invariant
invariant nonempty_actions(uint40 payloadID, uint256 actionID)
	getActionsLength(payloadID) != 0 && actionID < getActionsLength(payloadID) 
		=> getActionAccessLevel(payloadID, actionID) != PayloadsControllerUtils.AccessControl.Level_null;


/// @title executor of a valid action is not address(0)
/// @dev a helper invariant
invariant executor_exists(uint40 payloadID, uint256 actionID)
	getActionsLength(payloadID) != 0 && actionID < getActionsLength(payloadID) 
		=> get_action_executor(payloadID, actionID) != 0;

/// @title Action's accessLevel is not null iff it's executor is not address(0)
invariant executor_exists_iff_action_not_null(uint40 payloadID, uint256 actionID)
	getActionAccessLevel(payloadID, actionID) == PayloadsControllerUtils.AccessControl.Level_null 
		<=> get_action_executor(payloadID, actionID) == 0;


/// @title A payload maximal access level is greater than or equal to the access level of its action
invariant payload_maximal_access_level_gt_action_access_level(uint40 payloadID, uint256 actionID)
	getActionAccessLevel(payloadID, actionID) ==  PayloadsControllerUtils.AccessControl.Level_2  => 
		getMaximumAccessLevelRequired(payloadID) == PayloadsControllerUtils.AccessControl.Level_2
	{
	preserved{
		requireInvariant empty_actions_if_out_of_bound_payload(payloadID);
		}
	}	


/// @title Action's accessLevel is not null if it's executor is not address(0)
invariant executor_exists_if_action_not_null(uint40 payloadID, uint256 actionID)
	getActionAccessLevel(payloadID, actionID) != PayloadsControllerUtils.AccessControl.Level_null 
		=> get_action_executor(payloadID, actionID) != 0;


/// @title Action's accessLevel is not null only if it's executor is not address(0)
invariant executor_exists_only_if_action_not_null(uint40 payloadID, uint256 actionID)
	getActionAccessLevel(payloadID, actionID) == PayloadsControllerUtils.AccessControl.Level_null 
		=> get_action_executor(payloadID, actionID) == 0;


//
// Additional properties
//


// Reported a violation; Solidity had been fixed. 
/// @title A valid payload must have valid maximal access level 
invariant  null_access_level_only_if_out_of_bound_payload(uint40 id)
	id < getPayloadsCount() => getMaximumAccessLevelRequired(id) != PayloadsControllerUtils.AccessControl.Level_null;




//
// From properties.md
//

/// @title Property #1: Payloads IDs are consecutive
rule consecutiveIDs(method f) filtered { f-> !f.isView }{

	env e1; env e2; env e3;
	calldataarg args1; calldataarg args2; calldataarg args3;

	mathint id_first  = createPayload(e1, args1);
	f(e2, args2);
	mathint id_second  = createPayload(e3, args3);
	assert  ((f.selector != sig:createPayload(IPayloadsControllerCore.ExecutionAction[]).selector) =>  (id_second == id_first + 1));
	assert  ((f.selector == sig:createPayload(IPayloadsControllerCore.ExecutionAction[]).selector) =>  (id_second == id_first + 2));

}

/// @title Property #2: A payload must have at least one action
/// @notice An initialized payload has at least one action 
/// @notice A payload is empty if its max access level is Null or the state is None or expiration time is zero.  
invariant empty_actions_only_if_uninitialized_payload (uint40 id)
	(getMaximumAccessLevelRequired(id) != PayloadsControllerUtils.AccessControl.Level_null
	|| getPayloadStateVariable(id) != IPayloadsControllerCore.PayloadState.None
	|| getExpirationTime(id) != 0 )
	 => getActionsLength(id) > 0
	{
	preserved{
		requireInvariant empty_actions_if_out_of_bound_payload(id);
	 }
	}	

/// @title A payload with no actions is uninitialized
invariant  empty_actions_if_uninitialized_payload(uint40 id)
	((getActionsLength(id) > 0) => (getMaximumAccessLevelRequired(id) != PayloadsControllerUtils.AccessControl.Level_null) );

/// @title A payload has actions if and only if it's initialized
invariant  empty_actions_iff_uninitialized(uint40 id)
	((getMaximumAccessLevelRequired(id) == PayloadsControllerUtils.AccessControl.Level_null) <=> (getActionsLength(id) == 0))
	{
	preserved{
		requireInvariant null_access_level_if_out_of_bound_payload(id);
		}
	}	



/// @title Property #3.1 : The following Payload params can only be set once during payload creation: ipfsHash 
///	@notice	verify that additional params are immutable: accessLevel, maximumAccessLevelRequired, creator, createdAt, expirationTime
rule payload_fields_immutable_after_createPayload(method f, uint40 id)filtered { f-> !f.isView }{
	env e1; env e2;
	calldataarg args1; calldataarg args2;

	createPayload(e1, args1);
	uint40 payload_count = getPayloadsCount();

	address creator_before;
    PayloadsControllerUtils.AccessControl maximumAccessLevelRequired_before;
    IPayloadsControllerCore.PayloadState state_before;
    uint40 createdAt_before;
    uint40 queuedAt_before;
    uint40 executedAt_before;
    uint40 cancelledAt_before;
    uint40 expirationTime_before;
	uint40 delay_before;
    uint40 gracePeriod_before;
	
	creator_before, maximumAccessLevelRequired_before, state_before, createdAt_before,
	queuedAt_before, executedAt_before, cancelledAt_before, expirationTime_before,
	delay_before, gracePeriod_before =
		getPayloadFieldsById(id);

	f(e2, args2);

	address creator_after;
    PayloadsControllerUtils.AccessControl maximumAccessLevelRequired_after;
    IPayloadsControllerCore.PayloadState state_after;
    uint40 createdAt_after;
    uint40 queuedAt_after;
    uint40 executedAt_after;
    uint40 cancelledAt_after;
    uint40 expirationTime_after;
	uint40 delay_after;
    uint40 gracePeriod_after;
	
	creator_after, maximumAccessLevelRequired_after, state_after, createdAt_after,
	queuedAt_after, executedAt_after, cancelledAt_after, expirationTime_after,
	delay_after, gracePeriod_after =
		getPayloadFieldsById(id);

	assert id < payload_count => creator_before == creator_after;
	assert id < payload_count => maximumAccessLevelRequired_before == maximumAccessLevelRequired_after;
	assert id < payload_count => createdAt_before == createdAt_after;
	assert id < payload_count => expirationTime_before == expirationTime_after;
	assert id < payload_count => delay_before == delay_after;
	assert id < payload_count => gracePeriod_before == gracePeriod_after;

}



/// @title Payload fields can be initialized only once: ipfsHash, accessLevel, maximumAccessLevelRequired, creator, createdAt, expirationTime
rule initialized_payload_fields_are_immutable(method f, uint40 id)filtered { f-> !f.isView }{
	env e;
	calldataarg args;

	requireInvariant null_access_level_if_out_of_bound_payload(id);
	requireInvariant null_creator_and_zero_expiration_time_if_out_of_bound_payload(id);

	address creator_before;
    PayloadsControllerUtils.AccessControl maximumAccessLevelRequired_before;
    IPayloadsControllerCore.PayloadState state_before;
    uint40 createdAt_before;
    uint40 queuedAt_before;
    uint40 executedAt_before;
    uint40 cancelledAt_before;
    uint40 expirationTime_before;
	uint40 delay_before;
    uint40 gracePeriod_before;
	
	creator_before, maximumAccessLevelRequired_before, state_before, createdAt_before,
	queuedAt_before, executedAt_before, cancelledAt_before, expirationTime_before, delay_before, gracePeriod_before =
		getPayloadFieldsById(id);
	f(e, args);

	address creator_after;
    PayloadsControllerUtils.AccessControl maximumAccessLevelRequired_after;
    IPayloadsControllerCore.PayloadState state_after;
    uint40 createdAt_after;
    uint40 queuedAt_after;
    uint40 executedAt_after;
    uint40 cancelledAt_after;
    uint40 expirationTime_after;
	uint40 delay_after;
    uint40 gracePeriod_after;
	
	creator_after, maximumAccessLevelRequired_after, state_after, createdAt_after,
	queuedAt_after, executedAt_after, cancelledAt_after, expirationTime_after, delay_after, gracePeriod_after =
		getPayloadFieldsById(id);

	assert maximumAccessLevelRequired_before != PayloadsControllerUtils.AccessControl.Level_null => creator_before == creator_after;
	assert maximumAccessLevelRequired_before != PayloadsControllerUtils.AccessControl.Level_null =>
												maximumAccessLevelRequired_before == maximumAccessLevelRequired_after;
	assert maximumAccessLevelRequired_before != PayloadsControllerUtils.AccessControl.Level_null => createdAt_before == createdAt_after;
	assert maximumAccessLevelRequired_before != PayloadsControllerUtils.AccessControl.Level_null => expirationTime_before == expirationTime_after;
	assert maximumAccessLevelRequired_before != PayloadsControllerUtils.AccessControl.Level_null => delay_before == delay_after;
	assert maximumAccessLevelRequired_before != PayloadsControllerUtils.AccessControl.Level_null => gracePeriod_before == gracePeriod_after;

	assert creator_before != 0 => creator_before == creator_after;
	assert expirationTime_before != 0 => expirationTime_before == expirationTime_after;

	assert gracePeriod_before != 0 => delay_before == delay_after;
	assert gracePeriod_before != 0 => gracePeriod_before == gracePeriod_after;

}



/// @title Property #3.2 : The following Payload params can only be set once during payload creation:
///         actions fields:  target, withDelegateCall, accessLevel, value, signature, callDAta

//todo: this rule should replace the following 3 rules once CERT-2451 (timeout) is resolved
// rule action_immutable_2451(method f)filtered { f-> !f.isView }{

// 	env e;
// 	calldataarg args;
// 	uint40 payloadID;
// 	uint256 action_index;
	
// 	require getActionsLength(payloadID) < 2^100;


// 	IPayloadsControllerCore.ExecutionAction action_before = getAction(payloadID, action_index);
// 	f(e, args);
// 	IPayloadsControllerCore.ExecutionAction action_after = getAction(payloadID, action_index);

// 	assert action_before.target == action_after.target;
// 	assert action_before.withDelegateCall == action_after.withDelegateCall;
// 	assert action_before.accessLevel == action_after.accessLevel;
// 	assert action_before.value == action_after.value;
// 	assert compare(action_before.signature, action_after.signature);
// 	assert compare(action_before.callData, action_after.callData);
// }

rule action_immutable_check_only_fixed_size_fields(method f)filtered { f-> !f.isView }{

	env e;
	calldataarg args;
	uint40 payloadID;
	uint256 action_index;
	
	require getActionsLength(payloadID) < 2^100;


	IPayloadsControllerCore.ExecutionAction action_before = getAction(payloadID, action_index);
	f(e, args);
	IPayloadsControllerCore.ExecutionAction action_after = getAction(payloadID, action_index);

	assert action_before.target == action_after.target;
	assert action_before.withDelegateCall == action_after.withDelegateCall;
	assert action_before.accessLevel == action_after.accessLevel;
	assert action_before.value == action_after.value;
}

/// @title Property #3.2.2 : The following Payload params can only be set once during payload creation:
///         actions fields:  target, withDelegateCall, accessLevel, value
/// @dev check fixed-size fields only
//todo: remove rule once CERT-2451 (timeout) is resolved
rule action_immutable_fixed_size_fields(method f){

	env e;
	calldataarg args;
	uint40 payloadID;
	uint256 action_index;
	
	require getActionsLength(payloadID) < 2^100;
	
	address target_before;
    bool withDelegateCall_before;
    PayloadsControllerUtils.AccessControl accessLevel_before;
    uint256 value_before;
	target_before, withDelegateCall_before, accessLevel_before, value_before = getActionFixedSizeFields(payloadID, action_index);

	f(e, args);
	address target_after;
    bool withDelegateCall_after;
    PayloadsControllerUtils.AccessControl accessLevel_after;
    uint256 value_after;
	target_after, withDelegateCall_after, accessLevel_after, value_after = getActionFixedSizeFields(payloadID, action_index);

	assert target_before == target_after;
	assert withDelegateCall_before == withDelegateCall_after;
	assert accessLevel_before == accessLevel_after;
	assert value_before == value_after;
}


/// @title Property #3.2.3 : The following Payload params can only be set once during payload creation:
///         actions fields: signature
/// @dev check signature only to reduce rune time
//todo: remove rule once CERT-2451 (timeout) is resolved
rule action_signature_immutable(method f)filtered { f-> !f.isView }{

	env e;
	calldataarg args;
	uint40 payloadID;
	uint256 action_index;
	
	require getActionsLength(payloadID) < 2^100;// todo: remove and add flag --optimistic_storage_array_length once CERT-2577 is resolved

	string signature_before = getActionSignature(payloadID, action_index);
	f(e, args);
	string signature_after = getActionSignature(payloadID, action_index);
	assert  compare(signature_before, signature_after);
}


/// @title Property #3.2.3 : The following Payload params can only be set once during payload creation:
///         actions fields: callData
/// @dev check callData only to reduce rune time
//todo: remove rule once CERT-2451 (timeout) is resolved
rule action_callData_immutable(method f) filtered { f-> !f.isView }
{

	env e;
	calldataarg args;
	uint40 payloadID;
	uint256 action_index;

	require getActionsLength(payloadID) < 2^100;// todo: remove and add flag --optimistic_storage_array_length once CERT-2577 is resolved

	bytes callData_before = getActionCallData(payloadID, action_index);
	f(e, args);
	bytes callData_after = getActionCallData(payloadID, action_index);
	assert compare(callData_before, callData_after);
}



// @title Property #4: An Executor must exist of the max level required for the payload actions (action must be able to be executed)

// Payload executor is not address zero
rule executor_exists_after_createPayload() 
{
	env e;
	calldataarg args;
	uint256 actionID;
	uint40 payloadID = createPayload(e,args);
	
	IPayloadsControllerCore.ExecutionAction action = getAction(payloadID, actionID); 
	IPayloadsControllerCore.ExecutorConfig executorCfg = getExecutorSettingsByAccessControl(action.accessLevel);
	
	requireInvariant executor_exists(payloadID, actionID);
	assert executorCfg.executor != 0;
}

// @title action access level is not null after creation
// @dev split rules to reduce run time
// Payload action access level is not null
rule action_access_level_isnt_null_after_createPayload() 
{
	env e;
	calldataarg args;
	
	uint40 payloadID = createPayload(e,args);
	uint256 actionID;
	IPayloadsControllerCore.ExecutionAction action = getAction(payloadID, actionID); 

	requireInvariant nonempty_actions(payloadID, actionID);
	assert action.accessLevel != PayloadsControllerUtils.AccessControl.Level_null;
}

// Payload maximal access level is not null
rule executor_of_maximumAccessLevelRequired_exists_after_createPayload() 
{
	env e;
	calldataarg args;
	uint40 id = createPayload(e,args);

	assert get_executor_of_maximumAccessLevelRequired(id) != 0;

	PayloadsControllerUtils.AccessControl maximumAccessLevelRequired = getMaximumAccessLevelRequired(id);
	assert maximumAccessLevelRequired != PayloadsControllerUtils.AccessControl.Level_null;
	
}

// Once set the executor of a payload maximal access level is not address zero
rule executor_of_maximumAccessLevelRequired_exists(method f) filtered { f-> !f.isView }
{
	env e;
	calldataarg args;
	uint40 id;
	require get_executor_of_maximumAccessLevelRequired(id) != 0;
	f(e,args);
	assert get_executor_of_maximumAccessLevelRequired(id) != 0;
}


/// @title Property #5: A Payload can only be executed when in queued state and time lock has finished and before the grace period has passed.
/// @notice executePayload()  should not check check gracePeriod of every actions.
/// @notice it checks only the executor of the maximal access level.
rule execute_before_delay__maximumAccessLevelRequired{
	env e;
	uint40 id;
	requireInvariant payload_grace_period_eq_global_grace_period(id);
	requireInvariant null_access_level_iff_state_is_none(id);

	executePayload(e, id);
	mathint timestamp = e.block.timestamp;
	assert timestamp > getPayloadQueuedAt(id) + getPayloadDelay(id);
	assert timestamp < getPayloadQueuedAt(id) +  getPayloadDelay(id) + GRACE_PERIOD();
}


// @title A Payload can only be executed when in queued state 
rule executed_when_in_queued_state_variable{
	env e;
	uint40 payloadId;

	IPayloadsControllerCore.PayloadState state_before = getPayloadStateVariable(payloadId);
	executePayload(e,payloadId);
	assert state_before == IPayloadsControllerCore.PayloadState.Queued;
}

rule executed_when_in_queued_state{
	env e;
	uint40 payloadId;

	IPayloadsControllerCore.PayloadState state_before = getPayloadState(e, payloadId);
	executePayload(e,payloadId);
	assert state_before == IPayloadsControllerCore.PayloadState.Queued;
}



// @title property #7: The Guardian can cancel a Payload if it has not been executed
// A payload cannot execute after a guardian cancelled it
rule guardian_can_cancel{

	env e;
	calldataarg args;
	uint40 payloadId;
	IPayloadsControllerCore.PayloadState state_before = getPayloadState(e, payloadId);
	cancelPayload@withrevert(e, payloadId);
        bool call_reverted = lastReverted;
	assert 
		e.msg.sender == guardian() && 
		(state_before ==  IPayloadsControllerCore.PayloadState.Created ||
		state_before ==  IPayloadsControllerCore.PayloadState.Queued) => !call_reverted ;


}

/// @title One can not cancel a payload before its creation
// It's impossible to cancel before creation
rule no_early_cancellation{
	env e1; env e2;
	calldataarg args;
	uint40 payloadId1;

	requireInvariant null_state_variable_if_out_of_bound_payload(payloadId1);
	cancelPayload(e1, payloadId1);
	uint40 payloadId2 = createPayload(e2,args);
	assert payloadId1 < getPayloadsCount();
	assert payloadId1 != payloadId2;
}

/// @title One can not cancel a payload after its execution 
//It's impossible to cancel a payload after is was executed
rule no_late_cancel{

	env e1; env e2; env e3;
	calldataarg args;
	method f;
	uint40 payloadId;
	requireInvariant null_state_variable_if_out_of_bound_payload(payloadId);
	executePayload(e1,payloadId);
	f(e2, args);
	cancelPayload@withrevert(e3, payloadId);
	assert lastReverted ;
}


/// @title Property #8: Payload State can’t decrease
// Forward progress of payload state machine
rule state_variable_cant_decrease(method f) filtered { f -> !f.isView}
{
	env e;
	calldataarg args;
	uint40 payloadId;

	requireInvariant null_state_variable_if_out_of_bound_payload(payloadId);

	IPayloadsControllerCore.PayloadState state_before = getPayloadStateVariable(payloadId);
	f(e,args);
	IPayloadsControllerCore.PayloadState state_after = getPayloadStateVariable(payloadId);
	
 	assert assert_uint256(state_before) <= assert_uint256(state_after);
}

rule state_cant_decrease(method f) filtered { f -> !f.isView}
{
	env e;
	calldataarg args;
	uint40 payloadId;

	requireInvariant null_state_variable_if_out_of_bound_payload(payloadId);

	IPayloadsControllerCore.PayloadState state_before = getPayloadState(e, payloadId);
	f(e,args);
	IPayloadsControllerCore.PayloadState state_after = getPayloadState(e, payloadId);
	
 	assert assert_uint256(state_before) <= assert_uint256(state_after);
}

/// @title Property #9: No further state transitions are possible if proposal.state > 3
/// @notice The rule uses a getter function

rule no_transition_beyond_state_gt_3(method f) filtered { f -> !f.isView}{
	
	env e;
	calldataarg args;
	uint40 payloadId;

	requireInvariant null_state_variable_if_out_of_bound_payload(payloadId);

	IPayloadsControllerCore.PayloadState state_before = getPayloadState(e,payloadId);
	f(e,args);
	IPayloadsControllerCore.PayloadState state_after = getPayloadState(e,payloadId);
	
	assert assert_uint256(state_before) > 3 => state_before == state_after; 
}

/// @title Property #9.1: No further state transitions are possible if proposal.state > 3
/// @notice The rule checks storage directly
rule no_transition_beyond_state_variable_gt_3{
	
	env e;
	calldataarg args;
	method f;
	uint40 payloadId;

	requireInvariant null_state_variable_if_out_of_bound_payload(payloadId);
	IPayloadsControllerCore.PayloadState state_before = getPayloadStateVariable(payloadId);
	f(e,args);
	IPayloadsControllerCore.PayloadState state_after = getPayloadStateVariable(payloadId);
	assert assert_uint256(state_before) > 3 => state_before == state_after; 
}


//
// Additional rules
//


// @title Payload's grace period is equal to the contract grace period
invariant payload_grace_period_eq_global_grace_period(uint40 id)
	getMaximumAccessLevelRequired(id) != PayloadsControllerUtils.AccessControl.Level_null 
	=> getPayloadGracePeriod(id) == GRACE_PERIOD();


invariant zero_payload_grace_period_before_payload_creation(uint40 id)
	getMaximumAccessLevelRequired(id) == PayloadsControllerUtils.AccessControl.Level_null 
	=> getPayloadGracePeriod(id) == 0;



// @title Payload's delay is in [MIN_EXECUTION_DELAY, MAX_EXECUTION_DELAY]
invariant payload_delay_within_range(uint40 id)
	getMaximumAccessLevelRequired(id) != PayloadsControllerUtils.AccessControl.Level_null => 
			getPayloadDelay(id) >= MIN_EXECUTION_DELAY() && getPayloadDelay(id) <= MAX_EXECUTION_DELAY()
	{
	preserved {
		requireInvariant executor_access_level_within_range(PayloadsControllerUtils.AccessControl.Level_1);
		requireInvariant executor_access_level_within_range(PayloadsControllerUtils.AccessControl.Level_2);
		}
	}


// @title Executor delay of payload's max access level is in [MIN_EXECUTION_DELAY, MAX_EXECUTION_DELAY]
invariant delay_of_executor_of_max_access_level_within_range(uint40 id)
	getMaximumAccessLevelRequired(id) != PayloadsControllerUtils.AccessControl.Level_null => 
	get_delay_of_maximumAccessLevelRequired(id) >= MIN_EXECUTION_DELAY() && get_delay_of_maximumAccessLevelRequired(id) <= MAX_EXECUTION_DELAY()
	{
		preserved {
			requireInvariant executor_access_level_within_range(PayloadsControllerUtils.AccessControl.Level_1);
			requireInvariant executor_access_level_within_range(PayloadsControllerUtils.AccessControl.Level_2);
		}
	}

// @title Executor delay is in [MIN_EXECUTION_DELAY, MAX_EXECUTION_DELAY]
invariant executor_access_level_within_range(PayloadsControllerUtils.AccessControl access_level)
	get_executor(access_level) != 0 => 	
		get_delay(access_level) >= MIN_EXECUTION_DELAY() && get_delay(access_level) <= MAX_EXECUTION_DELAY();

// check that the same executor is not being used in 2 different levels
invariant executor_isnt_used_twice(PayloadsControllerUtils.AccessControl levelA, PayloadsControllerUtils.AccessControl levelB )
	get_executor(levelA) != 0 => (levelA != levelB <=> get_executor(levelA) != get_executor(levelB))
	{
		preserved
		{
			requireInvariant executor_of_level_null_is_zero;
		}

	}

invariant executor_of_level_null_is_zero()
	get_executor(PayloadsControllerUtils.AccessControl.Level_null) == 0;


rule checkUpdateExecutors {
  env e;
  IPayloadsControllerCore.UpdateExecutorInput[] executors;
  require executors.length == 2;
  updateExecutors(e, executors);

  PayloadsControllerUtils.AccessControl levelA;
  PayloadsControllerUtils.AccessControl levelB;
  address executorA;
  address executorB;
	
  bool no_duplicate_access_level = executors[0].accessLevel != executors[1].accessLevel;

  assert (executors[0].accessLevel == levelA && executors[0].executorConfig.executor == executorA && no_duplicate_access_level)
    => get_executor(levelA) == executorA;
  assert (executors[1].accessLevel == levelA && executors[1].executorConfig.executor == executorA && no_duplicate_access_level)
    => get_executor(levelA) == executorA;
  assert (executors[0].accessLevel == levelB && executors[0].executorConfig.executor == executorB && no_duplicate_access_level) 
    => get_executor(levelB) == executorB;
  assert (executors[1].accessLevel == levelB && executors[1].executorConfig.executor == executorB && no_duplicate_access_level)
    => get_executor(levelB) == executorB;

}


rule checkUpdateExecutors_witness_1
{
    env e;
	IPayloadsControllerCore.UpdateExecutorInput[] executors;
	updateExecutors(e, executors);

	PayloadsControllerUtils.AccessControl levelA; PayloadsControllerUtils.AccessControl levelB;
	address executorA; address executorB;	
	bool no_duplicate_access_level = executors[0].accessLevel != executors[1].accessLevel && executors.length <= 2;

	satisfy executors[0].accessLevel == levelA && executors[0].executorConfig.executor == executorA && no_duplicate_access_level;
}

rule checkUpdateExecutors_witness_2
{
    env e;
	IPayloadsControllerCore.UpdateExecutorInput[] executors;
	updateExecutors(e, executors);

	PayloadsControllerUtils.AccessControl levelA; PayloadsControllerUtils.AccessControl levelB;
	address executorA; address executorB;	
	bool no_duplicate_access_level = executors[0].accessLevel != executors[1].accessLevel && executors.length <= 2;

	require executors[0].accessLevel == levelA && executors[0].executorConfig.executor == executorA && no_duplicate_access_level;
	satisfy get_executor(levelA) == executorA;
}

rule checkUpdateExecutors_witness_3
{
    env e;
	IPayloadsControllerCore.UpdateExecutorInput[] executors;
	updateExecutors(e, executors);

	PayloadsControllerUtils.AccessControl levelA; PayloadsControllerUtils.AccessControl levelB;
	address executorA; address executorB;	
	bool no_duplicate_access_level = executors[0].accessLevel != executors[1].accessLevel && executors.length <= 2;

	satisfy executors[1].accessLevel == levelA && executors[1].executorConfig.executor == executorA && no_duplicate_access_level;
}

rule checkUpdateExecutors_witness_4
{
    env e;
	IPayloadsControllerCore.UpdateExecutorInput[] executors;
	updateExecutors(e, executors);

	PayloadsControllerUtils.AccessControl levelA; PayloadsControllerUtils.AccessControl levelB;
	address executorA; address executorB;	
	bool no_duplicate_access_level = executors[0].accessLevel != executors[1].accessLevel && executors.length <= 2;

	require executors[1].accessLevel == levelA && executors[1].executorConfig.executor == executorA && no_duplicate_access_level;
	satisfy get_executor(levelA) == executorA;
}


/// @title Property #6: A Payload can never be executed if it has not been queued before the EXPIRATION_DELAY defined.

/// @title Queue happens before creation time + EXPIRATION_DELAY
/// @notice assuming that the EXPIRATION_DELAY + CreatedAt <= max_uint40 
invariant queued_before_expiration_delay(uint40 id)
	getPayloadQueuedAt(id) <= require_uint40(EXPIRATION_DELAY() + getPayloadCreatedAt(id))
	{
		preserved with (env e){
			requireInvariant expirationTime_equal_to_createAt_plus_EXPIRATION_DELAY(id);
			//	requireInvariant created_in_the_past(e, id);
			requireInvariant queuedAt_is_zero_before_queued(e, id);
			//	requireInvariant executedAt_is_zero_before_executed(id);
			requireInvariant null_state_variable_if_out_of_bound_payload(id);
		}
	}

// helper invariant
/// @notice assuming that the EXPIRATION_DELAY + CreatedAt <= max_uint40 
invariant expirationTime_equal_to_createAt_plus_EXPIRATION_DELAY(uint40 id)
	getPayloadStateVariable(id) != IPayloadsControllerCore.PayloadState.None =>
		getExpirationTime(id) <= require_uint40(EXPIRATION_DELAY() + getPayloadCreatedAt(id));


//helper: creation time cannot be in the future
invariant created_in_the_past(env e1, uint40 id)
	getPayloadCreatedAt(id) <= require_uint40(e1.block.timestamp)
	{
		preserved with (env e2){
			require e1.block.timestamp == e2.block.timestamp;

		}
	}

/// @title Queue happens after creation time
// queuing time cannot occur after creation time
invariant queued_after_created(uint40 id)
	getPayloadQueuedAt(id) != 0 => getPayloadQueuedAt(id) >= getPayloadCreatedAt(id)
	{
		preserved with (env e){
			requireInvariant created_in_the_past(e, id);
			requireInvariant queuedAt_is_zero_before_queued(e, id);
			requireInvariant null_state_variable_if_out_of_bound_payload(id);
		}
	}

/// @title Execution happens after queue 
//execution time cannot be after queuing time
invariant executed_after_queue_state_variable(uint40 id)
	getPayloadStateVariable(id) == IPayloadsControllerCore.PayloadState.Executed =>
					getPayloadExecutedAt(id) >= getPayloadQueuedAt(id) 
	{
		preserved{
			requireInvariant executedAt_is_zero_before_executed_state_variable(id);
		}
	}

invariant executed_after_queue(env e1, uint40 id)
	getPayloadState(e1, id) == IPayloadsControllerCore.PayloadState.Executed =>
					getPayloadExecutedAt(id) >= getPayloadQueuedAt(id) ;


invariant zero_executedAt_if_not_executed_state_variable(uint40 id)
	getPayloadStateVariable(id) != IPayloadsControllerCore.PayloadState.Executed =>
					getPayloadExecutedAt(id) == 0 
	{
		preserved{
			requireInvariant null_state_variable_if_out_of_bound_payload(id);
		}
	}

invariant zero_executedAt_if_not_executed(env e, uint40 id)
	getPayloadState(e, id) != IPayloadsControllerCore.PayloadState.Executed =>
					getPayloadExecutedAt(id) == 0 
	{
		preserved{
			requireInvariant null_state_variable_if_out_of_bound_payload(id);
		}
	}

//helper: queuing time is nonzero for initialized payloads
invariant queuedAt_is_zero_before_queued_state_variable(uint40 id)
	getPayloadStateVariable(id) == IPayloadsControllerCore.PayloadState.None ||
	getPayloadStateVariable(id) == IPayloadsControllerCore.PayloadState.Created => getPayloadQueuedAt(id) == 0

{
		preserved{
			requireInvariant null_state_variable_if_out_of_bound_payload(id);
		}
	}

invariant queuedAt_is_zero_before_queued(env e, uint40 id)
	getPayloadState(e, id) == IPayloadsControllerCore.PayloadState.None ||
	getPayloadState(e, id) == IPayloadsControllerCore.PayloadState.Created => getPayloadQueuedAt(id) == 0

{
		preserved{
			requireInvariant null_state_variable_if_out_of_bound_payload(id);
		}
	}

//helper: ExecutedAt == 0 before execution
invariant executedAt_is_zero_before_executed_state_variable(uint40 id)
	getPayloadStateVariable(id) == IPayloadsControllerCore.PayloadState.None ||
	getPayloadStateVariable(id) == IPayloadsControllerCore.PayloadState.Created || 
	getPayloadStateVariable(id) == IPayloadsControllerCore.PayloadState.Queued => getPayloadExecutedAt(id) == 0

{
		preserved{
			requireInvariant null_state_variable_if_out_of_bound_payload(id);
		}
	}

invariant executedAt_is_zero_before_executed(env e, uint40 id)
	getPayloadState(e, id) == IPayloadsControllerCore.PayloadState.None ||
	getPayloadState(e, id) == IPayloadsControllerCore.PayloadState.Created || 
	getPayloadState(e, id) == IPayloadsControllerCore.PayloadState.Queued => getPayloadExecutedAt(id) == 0

{
		preserved with (env e2){
			requireInvariant null_state_variable_if_out_of_bound_payload(id);
			require e.block.timestamp == e2.block.timestamp;
		}
	}

// getPayloadState() is Null if and only if the state storage variable is None
invariant null_state_equivalence(env e, uint40 payloadId)
      getPayloadState(e, payloadId) == IPayloadsControllerCore.PayloadState.None <=> 
	  		getPayloadStateVariable(payloadId) == IPayloadsControllerCore.PayloadState.None;

//helper: One cannot queue a payload if expiration time have elapsed
rule no_queue_after_expiration{
	env e;
	uint40 payloadId;

	mathint expiration_time = getExpirationTime(payloadId);
	mathint timestamp = e.block.timestamp;
	address originSender;
    uint256 originChainId;
	PayloadsControllerUtils.AccessControl accessLevel;
	uint40 proposalVoteActivationTimestamp;

	//a message that encodes the above payloadId
	bytes message = encodeMessage(payloadId, accessLevel, proposalVoteActivationTimestamp);
	receiveCrossChainMessage(e, originSender, originChainId, message);

	assert expiration_time > timestamp;
}

// State-machine verification - check post-state of transitions
rule payload_state_transition_post_state(method f) filtered { f -> !f.isView}{
	
	env e1; env e2; env e3; calldataarg args1;
  	//require 0 < e1.block.timestamp;
  	require e1.block.timestamp <= e2.block.timestamp;
  	require e2.block.timestamp <= e3.block.timestamp;
  	require e3.block.timestamp < 2^40;
  	calldataarg args;
	
	uint40 payloadId;

	requireInvariant null_state_variable_if_out_of_bound_payload(payloadId);
	requireInvariant payload_grace_period_eq_global_grace_period(payloadId);
	requireInvariant null_access_level_iff_state_is_none(payloadId);
	requireInvariant expirationTime_equal_to_createAt_plus_EXPIRATION_DELAY(payloadId);

	IPayloadsControllerCore.PayloadState state1 = getPayloadState(e1,payloadId);
	f(e2,args);
	IPayloadsControllerCore.PayloadState state2 = getPayloadState(e3,payloadId);

	assert (e1.block.timestamp == e3.block.timestamp && state1 != state2) => ((state1 == IPayloadsControllerCore.PayloadState.None
				=> state2 == IPayloadsControllerCore.PayloadState.Created ));

	assert (e1.block.timestamp == e3.block.timestamp && state1 != state2) => (state1 == IPayloadsControllerCore.PayloadState.Created
				=> (state2 == IPayloadsControllerCore.PayloadState.Queued || state2 == IPayloadsControllerCore.PayloadState.Cancelled  ));

	assert (e1.block.timestamp == e3.block.timestamp && state1 != state2) => (state1 == IPayloadsControllerCore.PayloadState.Queued
				=> (state2 == IPayloadsControllerCore.PayloadState.Executed || state2 == IPayloadsControllerCore.PayloadState.Cancelled ));


	assert (e1.block.timestamp == e3.block.timestamp && state1 != state2) => ((state1 == IPayloadsControllerCore.PayloadState.None
				=> state2 == IPayloadsControllerCore.PayloadState.Created ));
	
	assert (e1.block.timestamp == e3.block.timestamp && state1 != state2) => (state1 == IPayloadsControllerCore.PayloadState.Created
				=> (state2 == IPayloadsControllerCore.PayloadState.Queued || state2 == IPayloadsControllerCore.PayloadState.Cancelled  ));

	assert (e1.block.timestamp == e3.block.timestamp && state1 != state2) => (state1 == IPayloadsControllerCore.PayloadState.Queued
				=> (state2 == IPayloadsControllerCore.PayloadState.Executed || state2 == IPayloadsControllerCore.PayloadState.Cancelled ));


}

// State-machine verification - check  pre-state of transitions
rule payload_state_transition_pre_state(method f) filtered { f -> !f.isView}{
	
	env e1; env e2; env e3; calldataarg args1;
//  	require 0 < e1.block.timestamp;
  	require e1.block.timestamp <= e2.block.timestamp;
  	require e2.block.timestamp <= e3.block.timestamp;
  	require e3.block.timestamp < 2^40;
  	calldataarg args;
	
	uint40 payloadId;

	requireInvariant null_state_variable_if_out_of_bound_payload(payloadId);
	//requireInvariant payload_grace_period_eq_global_grace_period(payloadId);
	//requireInvariant null_access_level_iff_state_is_none(payloadId);
	requireInvariant expirationTime_equal_to_createAt_plus_EXPIRATION_DELAY(payloadId);

	IPayloadsControllerCore.PayloadState state1 = getPayloadState(e1,payloadId);
	f(e2,args);
	IPayloadsControllerCore.PayloadState state2 = getPayloadState(e3,payloadId);

	assert (state1 != state2) => (state2 == IPayloadsControllerCore.PayloadState.Created
				=> state1 == IPayloadsControllerCore.PayloadState.None );

	assert (state1 != state2) => (state2 == IPayloadsControllerCore.PayloadState.Queued
				=> state1 == IPayloadsControllerCore.PayloadState.Created );

	assert (state1 != state2) => (state2 == IPayloadsControllerCore.PayloadState.Executed
				=> state1 == IPayloadsControllerCore.PayloadState.Queued );

	assert (state1 != state2) => (state2 == IPayloadsControllerCore.PayloadState.Cancelled
				=> (state1 == IPayloadsControllerCore.PayloadState.Created || state1 == IPayloadsControllerCore.PayloadState.Queued));

	assert (e2.block.timestamp == e3.block.timestamp  && state1 != state2) => (state2 == IPayloadsControllerCore.PayloadState.Expired
				=> (state1 == IPayloadsControllerCore.PayloadState.Created || state1 == IPayloadsControllerCore.PayloadState.Queued));

}


rule method_reachability{
  env e;
  calldataarg arg;
  method f;
  f(e, arg);
  satisfy true;
}



