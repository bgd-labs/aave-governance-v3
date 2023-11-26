import "votersRepresentedAddressSet.spec";


using GovernancePowerStrategy as _GovernancePowerStrategy;
//using VotingPortal as _VotingPortal;

methods {

  //
  // Summarizations
  //

  //call by modifier initializer, allow reachability of _initializeCore
  function _.isContract(address) internal => NONDET;


  // proposal power is fixed given a user and a timestamp 
  // allow proposal power to change over time
  function _GovernancePowerStrategy._getFullPowerByType(address user,IGovernancePowerDelegationToken.GovernancePowerType type) 
                      internal returns (uint256) with (env e) => get_fixed_user_and_type_power(e, user, type);

  // forwardMessage() sends a payload to execution chain, called by executeProposal()
  // forwardMessage() is verified at Delivery Infrastructure::CrossChainForwarder-simpleRules.spec
  function _.forwardMessage(uint256,address,uint256,bytes) external => NONDET;

  
  //
  //envfree
  //
  //Governance
  function PRECISION_DIVIDER() external returns (uint256) envfree;
  function ACHIEVABLE_VOTING_PARTICIPATION() external returns (uint256) envfree;
  function COOLDOWN_PERIOD() external returns (uint256) envfree;
  function getProposalsCount() external returns (uint256) envfree;
  function getVotingPortalsCount() external returns (uint256) envfree;
  function isVotingPortalApproved(address) external returns (bool) envfree;
  function getVotingConfig(PayloadsControllerUtils.AccessControl) external returns (IGovernanceCore.VotingConfig) envfree;
  function getRepresentativeByChain(address,uint256) external returns (address) envfree;
  function getRepresentedVotersByChain(address,uint256) external returns (address[] memory) envfree;
  function guardian() external returns (address) envfree;
  function owner() external returns (address) envfree;
  //GovernanceHarness
  function getPayloadLength(uint256 proposalId) external returns (uint256) envfree;
  function getProposalStateVariable(uint256 proposalId) external returns (IGovernanceCore.State) envfree;
  function getProposalCreator(uint256) external returns (address) envfree;
  function getProposalVotingPortal(uint256) external returns (address) envfree;
  function getProposalAccessLevel(uint256) external returns (PayloadsControllerUtils.AccessControl) envfree;
  function getProposalVotingDuration(uint256) external returns (uint24) envfree;
  function getProposalCreationTime(uint256) external returns (uint40) envfree;
  function getProposalIpfsHash(uint256) external returns (bytes32) envfree;
  function getProposalVotingActivationTime(uint256) external returns (uint40) envfree;
  function getProposalSnapshotBlockHash(uint256) external returns (bytes32) envfree;
  function getProposalCancellationFee(uint256) external returns (uint256) envfree;
  function getPayloadChain(uint256, uint256) external returns (uint256) envfree;
  function getPayloadAccessLevel(uint256,uint256) external returns (PayloadsControllerUtils.AccessControl) envfree;
  function getPayloadPayloadsController(uint256,uint256) external returns (address) envfree;
  function getPayloadPayloadId(uint256,uint256) external returns (uint40) envfree;
  function isRepresentativeOfVoter(address,address,uint256) external returns (bool) envfree;
}

ghost mapping(uint256 => mapping(address => mapping(IGovernancePowerDelegationToken.GovernancePowerType => uint256))) user_type_power;

function get_fixed_user_and_type_power(env e, address user, IGovernancePowerDelegationToken.GovernancePowerType type) returns uint256{
  return user_type_power[e.block.timestamp][user][type];
}


ghost mathint totalCancellationFee{
    init_state axiom totalCancellationFee == 0;
}
ghost bool isCancellationChanged;

hook Sstore _proposals[KEY uint256 proposalId].cancellationFee uint256 newFee
    (uint256 oldFee) STORAGE
{
    if (newFee != oldFee){
        isCancellationChanged = true;
    }
    totalCancellationFee = totalCancellationFee + newFee - oldFee;
}


// import invariants of AddressSet
use invariant setInvariant;
use invariant addressSetInvariant;
use invariant array_out_of_bound_entries_are_zero;
use rule set_size_eq_max_uint160_witness;

//  State changing methods
definition state_changing_function(method f) returns bool = 
            f.selector == sig:createProposal(PayloadsControllerUtils.Payload[],address,bytes32).selector ||
            f.selector == sig:activateVoting(uint256).selector ||
            f.selector == sig:queueProposal(uint256,uint128,uint128).selector ||
            f.selector == sig:executeProposal(uint256).selector ||
            f.selector == sig:cancelProposal(uint256).selector; 

definition initializeSig(method f) returns bool = 
            f.selector == sig:initialize(address,address,address, IGovernanceCore.SetVotingConfigInput[],address[],uint256,uint256).selector;

definition isTerminalState(IGovernanceCore.State state) returns bool = 
            state == IGovernanceCore.State.Executed ||      // 4
            state == IGovernanceCore.State.Failed ||        // 5
            state == IGovernanceCore.State.Cancelled ||     // 6 
            state == IGovernanceCore.State.Expired;         // 7


function getMinPropositionPower(IGovernanceCore.VotingConfig votingConfig) returns uint56{
  return votingConfig.minPropositionPower;
}



//
// from properties.md
//

// @title Property #1: Proposal IDs are consecutive and incremental.
// Proposal ID increments by 1 iff createProposal was called
rule consecutiveIDs(method f) filtered
{ f -> f.selector != sig:createProposal(PayloadsControllerUtils.Payload[],address,bytes32).selector 
        && !f.isView}
{

	env e1; env e2; env e3;
	calldataarg args1; calldataarg args2; calldataarg args3;

	mathint id_first  = createProposal(e1, args1);
	f(e2, args2);
	mathint id_second  = createProposal(e3, args3);
	assert  id_second == id_first + 1;
}


// @title Property #2: Every proposal should contain at least one payload.
// For initialized property, the proposal list is not empty
rule at_least_single_payload_active(method f)filtered { f-> !f.isView }
{
  env e1; env e2; env e3;
  calldataarg args;
  uint256 proposalId;
  
  requireInvariant empty_payloads_if_uninitialized_proposal(proposalId);
  require getProposalState(e1, proposalId) != IGovernanceCore.State.Null => getPayloadLength(proposalId) > 0;
  f(e2, args);
  assert getProposalState(e3, proposalId) != IGovernanceCore.State.Null => getPayloadLength(proposalId) > 0;
}

// Same property just referring directly to the storage
rule at_least_single_payload_active_variable(method f)filtered { f-> !f.isView }
{
  env e1; env e2; env e3;
  calldataarg args;
  uint256 proposalId;
  
  requireInvariant empty_payloads_if_uninitialized_proposal(proposalId);
  require getProposalStateVariable(e1, proposalId) != IGovernanceCore.State.Null => getPayloadLength(proposalId) > 0;
  f(e2, args);
  assert getProposalStateVariable(e3, proposalId) != IGovernanceCore.State.Null => getPayloadLength(proposalId) > 0;
}

//
// Valid state invariants 
//

// Address zero cannot be a creator of a proposal
invariant creator_is_not_zero(uint256 proposalId)
       getProposalStateVariable(proposalId) != IGovernanceCore.State.Null => getProposalCreator(proposalId) != 0
      {
        preserved with (env e)
        {require e.msg.sender != 0;}
      }

invariant creator_is_not_zero_2(uint256 proposalId)
       proposalId < getProposalsCount() => getProposalCreator(proposalId) != 0
      {
        preserved with (env e)
        {require e.msg.sender != 0;}
      }

// Uninitialized proposals has no payloads
invariant empty_payloads_iff_uninitialized_proposal(uint256 proposalId)
      proposalId >= getProposalsCount() <=> getPayloadLength(proposalId) == 0;

/* ND - this is just a subset of the above ? */
invariant empty_payloads_if_uninitialized_proposal(uint256 proposalId)
      proposalId >= getProposalsCount() => getPayloadLength(proposalId) == 0;

// A proposal is uninitialized iff its state is Null
invariant null_state_iff_uninitialized_proposal(env e, uint256 proposalId)
      proposalId >= getProposalsCount() <=> getProposalState(e, proposalId) == IGovernanceCore.State.Null;

invariant null_state_variable_iff_uninitialized_proposal(uint256 proposalId)
      proposalId >= getProposalsCount() <=> getProposalStateVariable(proposalId) == IGovernanceCore.State.Null;
/* ND - subset of null_state_iff_uninitialized_proposal ? */
invariant null_state_if_uninitialized_proposal(env e, uint256 proposalId)
      proposalId >= getProposalsCount() => getProposalState(e, proposalId) == IGovernanceCore.State.Null;
/* ND - subset of null_state_variable_iff_uninitialized_proposal */
invariant null_state_variable_if_uninitialized_proposal(uint256 proposalId)
      proposalId >= getProposalsCount() => getProposalStateVariable(proposalId) == IGovernanceCore.State.Null;

invariant null_state_only_if_uninitialized_proposal(env e, uint256 proposalId)
      getProposalState(e, proposalId) == IGovernanceCore.State.Null => proposalId >= getProposalsCount();

invariant null_state_variable_only_if_uninitialized_proposal(uint256 proposalId)
      getProposalStateVariable(proposalId) == IGovernanceCore.State.Null => proposalId >= getProposalsCount();
/* ND - it looks like if we prove that  

getProposalState(e, proposalId) == IGovernanceCore.State.Null <=> getProposalStateVariable(proposalId) == IGovernanceCore.State.Null

we can reduce many rules, even just one direction */

/* ND - numbering does not match report . maybe open a section valid state for all the above "helper" */ 
// @title Property #3: If a voting portal gets invalidated during the proposal life cycle, 
//      the proposal should not transition to any state apart from Cancelled, Expired, and Failed.
// Note: if voting power decreases after queuing the proposal can still be executed. 

rule proposal_after_voting_portal_invalidate(method f) filtered { f-> !f.isView }{

  env e1; env e2; env e3;
  calldataarg args; 
  uint256 proposalId;

  require e1.block.timestamp <= e3.block.timestamp;
  
  IGovernanceCore.State state_before = getProposalState(e1,proposalId);
  f(e2, args);
  bool voting_portal_approved_after = isVotingPortalApproved(getProposalVotingPortal(proposalId));

  // Checking if the a voting portal gets invalidated, regardless of the voting portal status before the state transition  
  IGovernanceCore.State state_after = getProposalState(e3, proposalId);

  assert !voting_portal_approved_after => (state_before != state_after => isTerminalState(state_after));
  


}

// @title Property #4: If the proposer's proposition power goes below the minimum required threshold, the proposal
//     should not go to any state apart from Failed or Canceled.
//     If time have elpased state could become Expired.
rule insufficient_proposition_power(method f) filtered {f -> !f.isView}
{
  env e1; env e2; env e3;
  calldataarg args;
  uint256 proposalId;
  
  require e1.block.timestamp <= e2.block.timestamp && e2.block.timestamp <= e3.block.timestamp;
  
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  f(e2, args);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);
  mathint creator_power = _GovernancePowerStrategy.getFullPropositionPower(e2,getProposalCreator(proposalId));
  mathint voting_config_min_power = getMinPropositionPower(getVotingConfig(getProposalAccessLevel(proposalId))) * PRECISION_DIVIDER(); //uint56

  bool belowThreshold = (state1 != state2 && creator_power <= voting_config_min_power );

  assert belowThreshold && e1.block.timestamp == e3.block.timestamp  => 
  state2 == IGovernanceCore.State.Cancelled || state2 == IGovernanceCore.State.Failed;

  assert belowThreshold => 
  state2 == IGovernanceCore.State.Cancelled || state2 == IGovernanceCore.State.Failed || state2 == IGovernanceCore.State.Expired;

}

//witness 1
rule insufficient_proposition_power_witness_failed{
  env e1; env e2; env e3;
  calldataarg args;
  uint256 proposalId;
  
  require e1.block.timestamp <= e2.block.timestamp && e2.block.timestamp <= e3.block.timestamp;
  
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  queueProposal(e2, args);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);
  mathint creator_power = _GovernancePowerStrategy.getFullPropositionPower(e2,getProposalCreator(proposalId));
  mathint voting_config_min_power = getMinPropositionPower(getVotingConfig(getProposalAccessLevel(proposalId))) * PRECISION_DIVIDER(); //uint56

  bool belowThreshold = (state1 != state2 && creator_power <= voting_config_min_power );

  require belowThreshold && e1.block.timestamp == e3.block.timestamp;

  satisfy belowThreshold && e1.block.timestamp == e3.block.timestamp => 
  state2 == IGovernanceCore.State.Failed;

}

//witness 2
rule insufficient_proposition_power_witness_cancelled{
  env e1; env e2; env e3;
  calldataarg args;
  uint256 proposalId;
  
  require e1.block.timestamp <= e2.block.timestamp && e2.block.timestamp <= e3.block.timestamp;
  
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  cancelProposal(e2, args);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);
  mathint creator_power = _GovernancePowerStrategy.getFullPropositionPower(e2,getProposalCreator(proposalId));
  mathint voting_config_min_power = getMinPropositionPower(getVotingConfig(getProposalAccessLevel(proposalId))) * PRECISION_DIVIDER(); //uint56

  bool belowThreshold = (state1 != state2 && creator_power <= voting_config_min_power );

  require belowThreshold && e1.block.timestamp == e3.block.timestamp;

  satisfy belowThreshold && e1.block.timestamp == e3.block.timestamp => state2 == IGovernanceCore.State.Cancelled;

}
//witness 3
rule insufficient_proposition_power_witness_time_elapsed(method f) filtered { f -> state_changing_function(f)}{
  env e1; env e2; env e3;
  calldataarg args;
  uint256 proposalId;
  
  require e1.block.timestamp <= e2.block.timestamp && e2.block.timestamp <= e3.block.timestamp;
  
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  f(e2, args);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);
  mathint creator_power = _GovernancePowerStrategy.getFullPropositionPower(e2,getProposalCreator(proposalId));
  mathint voting_config_min_power = getMinPropositionPower(getVotingConfig(getProposalAccessLevel(proposalId))) * PRECISION_DIVIDER(); //uint56

  bool belowThreshold = (state1 != state2 && creator_power <= voting_config_min_power );

  require belowThreshold;

  satisfy state2 == IGovernanceCore.State.Expired;
}


//helper a proposal state is Null iff its required access level is null
/* ND - move this to the other null valid state invariants */  
invariant null_state_variable_iff_null_access_level(uint256 proposalId)
      getProposalStateVariable(proposalId) == IGovernanceCore.State.Null <=> 
      getProposalAccessLevel(proposalId) == PayloadsControllerUtils.AccessControl.Level_null;


// ND - property #6 in report 
// Once assign the voting portal is immutable
rule immutable_voting_portal(method f) filtered { f-> !f.isView }{

  env e;
  calldataarg args;
  uint256 proposalId;

  requireInvariant zero_voting_portal_iff_uninitialized_proposal(proposalId);

  address votingPortal_before = getProposalVotingPortal(proposalId);
  f(e, args);
  address votingPortal_after = getProposalVotingPortal(proposalId);

  assert votingPortal_before != 0 => votingPortal_before == votingPortal_after;
}

// helper: A proposal is uninitialized iff its voting portal is address zero.
// ND - move up to "helpers"
invariant zero_voting_portal_iff_uninitialized_proposal(uint256 proposalId)
      proposalId >= getProposalsCount() <=> getProposalVotingPortal(proposalId) == 0
      {
        preserved {
          requireInvariant zero_address_is_not_a_valid_voting_portal();
        }

      }

//helper: Zero address is never an approved voting portal
// ND - move up
invariant zero_address_is_not_a_valid_voting_portal()
      !isVotingPortalApproved(0); 



// @title Property #7: No further state transitions are possible if proposal.state > 3.
// All state that are greater than 3 are terminal
rule no_state_transitions_beyond_3(method f) filtered { f-> !f.isView }{
  env e1; env e2; env e3;
  calldataarg args;
  uint256 proposalId;

  require e1.block.timestamp <= e2.block.timestamp;
  require e2.block.timestamp <= e3.block.timestamp;
  requireInvariant null_state_iff_uninitialized_proposal(e1, proposalId);
  
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  f(e2, args);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);

  assert assert_uint256(state1) > 3 => state1 == state2; 
  assert isTerminalState(state1) => state1 == state2; 
  
}


// @title Property #8 proposal.state can't decrease.
// Forward progress of the proposal state-machine: the state cannot decrease. 
rule state_cant_decrease(method f) filtered { f-> !f.isView }{
  env e1; env e2; env e3;
  calldataarg args;
  uint256 proposalId;

  require e1.block.timestamp <= e2.block.timestamp && e2.block.timestamp <= e3.block.timestamp;
  requireInvariant null_state_iff_uninitialized_proposal(e1, proposalId);
  
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  f(e2, args);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);

  assert assert_uint256(state1) <= assert_uint256(state2);
}

// @title Property #7 
// It should be impossible to do more than 1 state transition per proposal per block, except:
// (a) Cancellation because of the proposition power change.
// (b) Cancellation after proposal creation by creator.
// (c) Proposal execution after proposal queuing if COOLDOWN_PERIOD is 0.
// (d) The owner is calling setVotingConfigs(), removeVotingPortals()
// No two transitions of a proposal's state happen in a single block timestamp, except cancellation by the owner or by a guardian.

rule single_state_transition_per_block_non_creator_non_guardian(method f, method g, method h)
filtered { f -> state_changing_function(f), 
  g -> !g.isView  && !initializeSig(g),
  h -> state_changing_function(h) // must allow a second call to a state-changing function 
  }
{
  env e1;
  env e2;
  env e3;
  env e4;
  env e5;
  env e6;
  calldataarg args1;
  calldataarg args2;
  calldataarg args3;
  uint256 proposalId;

  require e1.block.timestamp <= e2.block.timestamp;
  require e2.block.timestamp == e3.block.timestamp; 
  require e3.block.timestamp == e4.block.timestamp;
  require e4.block.timestamp == e5.block.timestamp;
  require e5.block.timestamp == e6.block.timestamp;
  require e6.block.timestamp < 2^40;

  requireInvariant null_state_iff_uninitialized_proposal(e2, proposalId);
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  f(e2, args1);  // any method that can change the proposal state
  g(e3, args2);  // any non-view method
  IGovernanceCore.State state2 = getProposalState(e4, proposalId);
  mathint creator_power_before = _GovernancePowerStrategy.getFullPropositionPower(e4,getProposalCreator(proposalId));
  h(e5, args3);  // any method that can change the proposal state
  mathint creator_power_after = _GovernancePowerStrategy.getFullPropositionPower(e6,getProposalCreator(proposalId));
  IGovernanceCore.State state3 = getProposalState(e6, proposalId);

  assert getProposalCreator(proposalId) != e5.msg.sender && // creator can cancel
          creator_power_after < creator_power_before &&
          owner() != e3.msg.sender && //owner can call setVotingConfigs, removeVotingPortals
          COOLDOWN_PERIOD() != 0 &&
          state1 != state2 => state2 == state3;
}


rule single_state_transition_per_block_non_creator_witness
{
  env e1;
  env e2;
  env e3;
  env e4;
  env e5;
  calldataarg args1;
  calldataarg args2;
  uint256 proposalId;

  require e1.block.timestamp <= e2.block.timestamp;
  require e2.block.timestamp == e3.block.timestamp;
  require e3.block.timestamp == e4.block.timestamp;
  require e4.block.timestamp == e5.block.timestamp;
  require e5.block.timestamp < 2^40;
  requireInvariant null_state_iff_uninitialized_proposal(e2, proposalId);
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  queueProposal(e2, args1);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);
  executeProposal(e4, args2);
  IGovernanceCore.State state3 = getProposalState(e5, proposalId);

  require  getProposalCreator(proposalId) != e4.msg.sender; // creator can cancel
  require currentContract != e2.msg.sender;
  require currentContract != e4.msg.sender;
  require guardian() != e4.msg.sender;
  
  require state1 != state2;
  satisfy !(state2 == state3);
}



/// Property #8: Only the owner can set the voting power strategy and voting config.
// A unauthorized user (not an owner) cannot change voting parameters
rule only_owner_can_set_voting_config(method f) filtered {
   f -> !f.isView &&
   !initializeSig(f) }
{
  env e;
  calldataarg args;
  PayloadsControllerUtils.AccessControl accessLevel;

  IGovernanceCore.VotingConfig voting_config_before = getVotingConfig(accessLevel);
  f(e, args);
  IGovernanceCore.VotingConfig voting_config_after = getVotingConfig(accessLevel);

  assert e.msg.sender != owner() => voting_config_before.coolDownBeforeVotingStart ==  voting_config_after.coolDownBeforeVotingStart;
  assert e.msg.sender != owner() => voting_config_before.votingDuration ==  voting_config_after.votingDuration;
  assert e.msg.sender != owner() => voting_config_before.yesThreshold ==  voting_config_after.yesThreshold;
  assert e.msg.sender != owner() => voting_config_before.yesNoDifferential ==  voting_config_after.yesNoDifferential;
  assert e.msg.sender != owner() => voting_config_before.minPropositionPower ==  voting_config_after.minPropositionPower;

}

rule only_owner_can_set_voting_config_witness(method f) filtered { f -> !f.isView}
{
  env e;
  calldataarg args;
  PayloadsControllerUtils.AccessControl accessLevel;

  IGovernanceCore.VotingConfig voting_config_before = getVotingConfig(accessLevel);
  f(e, args);
  IGovernanceCore.VotingConfig voting_config_after = getVotingConfig(accessLevel);

  satisfy voting_config_before.coolDownBeforeVotingStart ==  voting_config_after.coolDownBeforeVotingStart;
  satisfy voting_config_before.votingDuration ==  voting_config_after.votingDuration;
  satisfy voting_config_before.yesThreshold ==  voting_config_after.yesThreshold;
  satisfy voting_config_before.yesNoDifferential ==  voting_config_after.yesNoDifferential;
  satisfy voting_config_before.minPropositionPower ==  voting_config_after.minPropositionPower;

}

//Property #9: When invalidating voting config, proposal can not be queued
// One can not queue a proposal if its voting portal is unapproved
rule cannot_queue_when_voting_portal_unapproved{
  env e1; env e2; env e3;
  calldataarg args; 
  method f;
  uint256 proposalId;
  uint128 forVotes;
  uint128 againstVotes;

  bool is_voting_portal_approved = isVotingPortalApproved(getProposalVotingPortal(proposalId));
  queueProposal(e1, proposalId, forVotes, againstVotes);
  assert is_voting_portal_approved;
}




//Property #10: Guardian can cancel proposals with proposal.state < 4
// A guardian can cancel a proposal whose state < 4 but it cannot cancel if state is >= 5
rule guardian_can_cancel()
{
  env e1;
  env e2;
  env e3;
  uint256 proposalId;

  require e1.block.timestamp <= e2.block.timestamp;

  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  cancelProposal(e2, proposalId);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);

  assert state2 == IGovernanceCore.State.Cancelled;
  assert assert_uint256(state1) < 4;
}

// property  : Only a guardian, an owner can cancel any proposal, a creator can cancel his own proposal 
rule only_guardian_can_cancel(method f)filtered 
{ f -> !f.isView  && 
  !initializeSig(f)
  }
{
  env e1;
  env e2;
  env e3;
  
  calldataarg args1;
  calldataarg args2;
  
  uint256 proposalId = createProposal(e1, args1);
  mathint creator_power_before = _GovernancePowerStrategy.getFullPropositionPower(e1,getProposalCreator(proposalId));
  f(e2, args2);
  mathint creator_power_after = _GovernancePowerStrategy.getFullPropositionPower(e3,getProposalCreator(proposalId));
  cancelProposal(e3, proposalId);

  assert guardian() == e2.msg.sender ||
         owner() == e2.msg.sender ||   //todo: review
         guardian() == e3.msg.sender || 
        getProposalCreator(proposalId) == e3.msg.sender ||
        creator_power_after < creator_power_before;
}


//Property #11: The following proposal parameters can only be set once, at proposal creation:
//               creator, accessLevel, votingPortal, votingDuration, creationTime, ipfsHash, payloads.
// Once a proposal is initialized its creator, accessLevel, votingPortal, votingDuration, creationTime, ipfsHash, payloads length cannot change.
rule immutable_after_creation(method f){

  env e1;
  env e2;
  calldataarg args;
  uint256 proposalId;


  requireInvariant null_state_iff_uninitialized_proposal(e2, proposalId);
 
  IGovernanceCore.State state_before = getProposalState(e1, proposalId);

  address creator_before = getProposalCreator(proposalId);
  address voting_portal_before = getProposalVotingPortal(proposalId);
  PayloadsControllerUtils.AccessControl access_level_before = getProposalAccessLevel(proposalId);
  uint24 voting_duration_before = getProposalVotingDuration(proposalId);
  uint40 creation_time_before = getProposalCreationTime(proposalId);
  bytes32 ipfs_hash_before = getProposalIpfsHash(proposalId);
  uint256 payloads_length_before = getPayloadLength(proposalId);

  f(e2, args);
  address creator_after = getProposalCreator(proposalId);
  address voting_portal_after = getProposalVotingPortal(proposalId);
  PayloadsControllerUtils.AccessControl access_level_after = getProposalAccessLevel(proposalId);
  uint24 voting_duration_after = getProposalVotingDuration(proposalId);
  uint40 creation_time_after = getProposalCreationTime(proposalId);
  bytes32 ipfs_hash_after = getProposalIpfsHash(proposalId);
  uint256 payloads_length_after = getPayloadLength(proposalId);


  assert state_before != IGovernanceCore.State.Null  => creator_before == creator_after;
  assert state_before != IGovernanceCore.State.Null  => access_level_before == access_level_after;
  assert state_before != IGovernanceCore.State.Null  => voting_portal_before == voting_portal_after;
  assert state_before != IGovernanceCore.State.Null  => voting_duration_before == voting_duration_before;
  assert state_before != IGovernanceCore.State.Null  => creation_time_before == creation_time_before;
  assert state_before != IGovernanceCore.State.Null  => ipfs_hash_before == ipfs_hash_after;
  assert state_before != IGovernanceCore.State.Null  => payloads_length_before == payloads_length_after;
}



// Proposal payloads cannot change.
/* ND - what about f == createProposal why is this passing */ 
rule immutable_payload_after_creation(method f){

  env e1;
  env e2;
  calldataarg args;
  uint256 proposalId;
  uint256 payloadId;

  requireInvariant null_state_iff_uninitialized_proposal(e2, proposalId);
  requireInvariant empty_payloads_iff_uninitialized_proposal(proposalId);
 
  IGovernanceCore.State state_before = getProposalState(e1, proposalId);

  uint256 payload_chain_before = getPayloadChain(proposalId, payloadId);
  PayloadsControllerUtils.AccessControl payload_access_level_before = getPayloadAccessLevel(proposalId, payloadId);
  address payloads_controller_before = getPayloadPayloadsController(proposalId, payloadId);
  uint40 payloads_id_before = getPayloadPayloadId(proposalId, payloadId);

  f(e2, args);
  uint256 payload_chain_after = getPayloadChain(proposalId, payloadId);
  PayloadsControllerUtils.AccessControl payload_access_level_after = getPayloadAccessLevel(proposalId, payloadId);
  address payloads_controller_after = getPayloadPayloadsController(proposalId, payloadId);
  uint40 payloads_id_after = getPayloadPayloadId(proposalId, payloadId);

  assert payload_chain_before == payload_chain_after;
  assert payload_access_level_before == payload_access_level_after;
  assert payloads_controller_before == payloads_controller_after;
  assert payloads_id_before == payloads_id_after;

}

// Property #12: The following proposal parameters can only be set once, during voting activation:
// votingActivationTime, snapshotBlockHash, snapshotBlockNumber.
// Proposal's votingActivationTime and snapshotBlockHash are immutable
rule immutable_after_activation(method f)
filtered {f -> !f.isView}
{
  env e1;
  env e2;
  calldataarg args;
  uint256 proposalId;

  activateVoting(e1, proposalId);
  
  uint40 voting_activation_time_before = getProposalVotingActivationTime(proposalId);
  bytes32 snapshot_blockhash_before = getProposalSnapshotBlockHash(proposalId);
  f(e2, args);
  uint40 voting_activation_time_after = getProposalVotingActivationTime(proposalId);
  bytes32 snapshot_blockhash_after = getProposalSnapshotBlockHash(proposalId);
  /* ND - we are not proving the "can only be set once... " we are proving "can not be changed after activateVoting"
  either rephrase of add a satisfy rule that shows it can be set */
  assert voting_activation_time_before == voting_activation_time_after;
  assert snapshot_blockhash_before == snapshot_blockhash_after;
}



//Property #14: Only a valid voting portal can queue a proposal and only if this is in Active state.
// Only by an approved voting protal can call queue(), only if state is Active
rule only_valid_voting_portal_can_queue_proposal(method f){

  env e1;
  env e2;
  env e3;
  calldataarg args;
  uint256 proposalId;
  require e1.block.timestamp <= e3.block.timestamp;

  IGovernanceCore.State state_before = getProposalState(e1, proposalId);
  f(e2, args);
  IGovernanceCore.State state_after = getProposalState(e3, proposalId);

  assert state_before != state_after && state_after == IGovernanceCore.State.Queued => isVotingPortalApproved(e2.msg.sender);
  assert state_before != state_after && state_after == IGovernanceCore.State.Queued => state_before == IGovernanceCore.State.Active;
}


//Property #15: A proposal can be executed only in Queued state, after passing the cooldown period.
// A proposal can be executed only after the cooldown period has elapsed since it was queued
rule proposal_executes_after_cooldown_period(){

  env e1;
  env e2;
  env e3;
  uint256 proposalId;
  uint128 forVotes;
  uint128 againstVotes;
  require e2.block.timestamp <= e3.block.timestamp;
  require e1.block.timestamp < 2^40;

  // record the time between queueProposal and executeProposal
  queueProposal(e1, proposalId, forVotes, againstVotes);
  IGovernanceCore.State state_before = getProposalState(e2, proposalId);
  executeProposal(e3, proposalId);

  assert state_before == IGovernanceCore.State.Queued;
  assert e3.block.timestamp - e1.block.timestamp >= to_mathint(COOLDOWN_PERIOD()); 
}


//Property #16: The Governance Core system shouldn’t know anything about the voting procedure.
//              It only expects a whitelisted entity to submit voting results about a specific proposal id.
//Property #17: The Governance Core system shouldn’t know anything about final execution.
//              From its perspective, execution is sent to a Portal.
//Property #18: VOTING_TOKENS_CAP in GovernanceCore should be big enough to account for tokens that need to pass multiple slots,
//               and big enough for at least mig to long term
// ND - what are the above 16 - 18 properties? 

//property #20: When if in a terminal state, no state changing function can be called.
// Terminal states >= 4 are terminal, a proposal in a terminal state cannot change its state
rule state_changing_function_cannot_be_called_while_in_terminal_state(method f) filtered {f -> state_changing_function(f)}
{
  env e1;
  env e2;
  env e3;
  uint256 proposalId;
  require e1.block.timestamp <= e2.block.timestamp;

  requireInvariant null_state_iff_uninitialized_proposal(e2, proposalId);
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  uint128 forVotes;
  calldataarg args;
  uint128 againstVotes;
  
  if (f.selector == sig:createProposal(PayloadsControllerUtils.Payload[],address,bytes32).selector ) {require createProposal(e2, args) == proposalId;}
    else if (f.selector == sig:activateVoting(uint256).selector) {activateVoting(e2, proposalId);}
    else if (f.selector == sig:queueProposal(uint256,uint128,uint128).selector) {queueProposal(e2, proposalId, forVotes, againstVotes);}
    else if (f.selector == sig:executeProposal(uint256).selector) {executeProposal(e2, proposalId);}
    else if (f.selector == sig:cancelProposal(uint256).selector) {cancelProposal(e2, proposalId);}
    else {assert false;} 


  assert !isTerminalState(state1);
  assert assert_uint256(state1) < 4;
}

// ND - try to organize - either top or bottom 



// Terminal states >= 4 are terminal, a proposal in a terminal state cannot change its state // ND - this is not realted to this rule, right? 
// Only the relevant state-changing function actually change the state
// Check by the states before a transition occurs 
rule pre_state(method f)
{
  env e1;
  env e2;
  env e3;
  calldataarg args1;
  uint256 proposalId;

    require e1.block.timestamp <= e3.block.timestamp;
  requireInvariant null_state_iff_uninitialized_proposal(e1, proposalId);
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  f(e2, args1);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);
  
  assert state1 != state2 && state1 == IGovernanceCore.State.Null && state2 != IGovernanceCore.State.Expired
      => f.selector == sig:createProposal(PayloadsControllerUtils.Payload[],address,bytes32).selector;
  assert state1 != state2 && state1 == IGovernanceCore.State.Created  && state2 != IGovernanceCore.State.Expired 
        => f.selector == sig:activateVoting(uint256).selector || f.selector == sig:cancelProposal(uint256).selector;
  assert state1 != state2 && state1 == IGovernanceCore.State.Active  && state2 != IGovernanceCore.State.Expired 
        => f.selector == sig:queueProposal(uint256,uint128,uint128).selector || f.selector == sig:cancelProposal(uint256).selector;
  assert state1 != state2 && state1 == IGovernanceCore.State.Queued  && state2 != IGovernanceCore.State.Expired 
        => (f.selector == sig:executeProposal(uint256).selector || f.selector == sig:cancelProposal(uint256).selector);
  //todo: relevant assertion for Failed, Expired?
 // ND - either do or remove , maybe have a section additional properties that can be added */
}


// Only the relevant state-changing function actually change the state 
// Check by the states after a transition occurs 
rule post_state(method f)
{
  env e1;
  env e2;
  env e3;
  calldataarg args1;
  uint256 proposalId;

    require e1.block.timestamp <= e3.block.timestamp;

  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  f(e2, args1);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);
  
  assert state1 != state2 && state2 == IGovernanceCore.State.Created => 
      f.selector == sig:createProposal(PayloadsControllerUtils.Payload[],address,bytes32).selector;
  assert state1 != state2 && state2 == IGovernanceCore.State.Active => f.selector == sig:activateVoting(uint256).selector;
  assert state1 != state2 && state2 == IGovernanceCore.State.Queued => f.selector == sig:queueProposal(uint256,uint128,uint128).selector;
  assert state1 != state2 && state2 == IGovernanceCore.State.Executed => f.selector == sig:executeProposal(uint256).selector;
  assert state1 != state2 && state2 == IGovernanceCore.State.Cancelled => f.selector == sig:cancelProposal(uint256).selector;
  //todo: relevant assertion for Failed, Expired?

}

//helper: only method of state_changing_function can change a proposal state  
rule state_changing_function_self_check(method f)
filtered { f -> !state_changing_function(f)}
{
  env e1;
  env e2;
  env e3;
  calldataarg args1;
  uint256 proposalId;

  require e1.block.timestamp <= e3.block.timestamp;
  IGovernanceCore.State state1 = getProposalState(e1, proposalId);
  f(e2, args1);
  IGovernanceCore.State state2 = getProposalState(e3, proposalId);
  
  assert state2 != IGovernanceCore.State.Expired => state1 == state2;
  assert e1.block.timestamp == e3.block.timestamp => state1 == state2;
}

rule state_variable_changing_function_self_check(method f)
filtered { f -> !state_changing_function(f)}
{
  env e1;
  env e2;
  env e3;
  calldataarg args;
  uint256 proposalId;

  IGovernanceCore.State state1 = getProposalStateVariable(e1, proposalId);
  f(e2, args);
  IGovernanceCore.State state2 = getProposalStateVariable(e3, proposalId);
  
  assert state1 == state2;
}

//
// Cancellation fee
//

// Property 22: For any proposal id that wasn't yet created, the cancellation fee must be 0
invariant cancellationFeeZeroForFutureProposals(uint256 proposalId) 
    proposalId >= getProposalsCount() => getProposalCancellationFee(proposalId) == 0;

// Property: eth balance can cover the total cancellation fee of users
invariant totalCancellationFeeEqualETHBalance()
// ND - the report regard fee of live proposals, this is all proposals, no? 
    to_mathint(nativeBalances[currentContract]) >= totalCancellationFee
    {
        preserved with (env e2)
        {
            require e2.msg.sender != currentContract;
        }
    }

// Property: In any case that proposal.CancellationFee doesn't change, eth balance cannot decrease
rule userFeeDidntChangeImplyNativeBalanceDidntDecrease(){
    require(!isCancellationChanged);
    uint256 _ethBal = nativeBalances[currentContract];
    method f; env e; calldataarg args;
    f(e, args);
    uint256 ethBal_ = nativeBalances[currentContract];
    assert(!isCancellationChanged => _ethBal <= ethBal_);
}

//
// Voting by representative
//

// A voter cannot represent himself
// ND - this is not in the report, why? 
invariant no_self_representative(address voter, uint256 chainId)
    voter == 0 <=> getRepresentativeByChain(voter, chainId) == voter
    {
      preserved with (env e){
        require e.msg.sender != 0;
      }
    }

// Address zero can be a representative (this property is implied by no_self_representative)
// No voter is contained in the voters' set of address zero
invariant no_representative_is_zero(address voter, uint256 chainId)
    !isRepresentativeOfVoter(voter, 0, chainId);

// The size of the voter's set of address zero is zero  
invariant no_representative_is_zero_2(uint256 chainId)
    getRepresentedVotersSize(0, chainId) == 0;

// Address zero has no representatives
invariant no_representative_of_zero(uint256 chainId)
    getRepresentativeByChain(0, chainId) == 0
    {
      preserved with (env e){
        require e.msg.sender != 0;
      }
    }

// The size of the new representative set is correct after updateRepresentatives()
rule check_new_representative_set_size_after_updateRepresentatives{

    env e;
    address new_representative;
    uint256 chainId;

    requireInvariant no_self_representative(e.msg.sender, chainId);
    requireInvariant in_representatives_iff_in_votersRepresented(e.msg.sender, new_representative, chainId);
 

    address[] new_voters_before = getRepresentedVotersByChain(new_representative, chainId);
    mathint new_voters_size_before = new_voters_before.length;
    address representative_before = getRepresentativeByChain(e.msg.sender, chainId);
  
    updateSingleRepresentativeForChain(e, new_representative, chainId);
    address[] new_voters_after = getRepresentedVotersByChain(new_representative, chainId);
    mathint new_voters_size_after = new_voters_after.length;
    address representative_after = getRepresentativeByChain(e.msg.sender, chainId);

    
    assert new_representative != 0  && new_representative !=e.msg.sender && new_representative != representative_before =>
        new_voters_size_after == new_voters_size_before + 1;

    assert new_representative != 0  && new_representative !=e.msg.sender && new_representative == representative_before =>
        new_voters_size_after == new_voters_size_before;

    assert (new_representative == e.msg.sender ) =>
      new_voters_size_after == new_voters_size_before;

}

// The size of the old representative set is correct after updateRepresentatives()
rule check_old_representative_set_size_after_updateRepresentatives{

    env e;
    address new_representative;
    uint256 chainId;

    address representative_before = getRepresentativeByChain(e.msg.sender, chainId);

    requireInvariant in_representatives_iff_in_votersRepresented(e.msg.sender, representative_before, chainId);
    requireInvariant no_representative_is_zero_2(chainId);

    address[] old_voters_before = getRepresentedVotersByChain(representative_before, chainId);
    mathint old_voters_size_before = old_voters_before.length;
    
    updateSingleRepresentativeForChain(e, new_representative, chainId);
    address[] old_voters_after = getRepresentedVotersByChain(representative_before, chainId);
    mathint old_voters_size_after = old_voters_after.length;
    address representative_after = getRepresentativeByChain(e.msg.sender, chainId);

    
    assert new_representative != 0  && new_representative !=e.msg.sender 
          && new_representative != representative_before  && old_voters_size_before > 0 =>
        old_voters_size_after + 1 == old_voters_size_before;

    assert new_representative != 0  && new_representative !=e.msg.sender && new_representative == representative_before =>
        old_voters_size_after == old_voters_size_before;

    assert (new_representative == e.msg.sender || new_representative == 0)  && old_voters_size_before > 0 =>
      old_voters_size_after + 1 == old_voters_size_before;

}

invariant no_representative_of_zero_in_set(address representative, uint256 chainId)
    !isRepresentativeOfVoter(0, representative, chainId)
 {
      preserved with (env e){
        require e.msg.sender != 0;
        requireInvariant addressSetInvariant(representative, chainId);
      }
    }

// helper
invariant in_representatives_iff_in_votersRepresented(address voter, address representative, uint256 chainId)
    (representative != 0) =>  
        (isRepresentativeOfVoter(voter, representative, chainId) <=> 
        getRepresentativeByChain(voter, chainId) == representative)  //parentheses are required here!
    {
      preserved with (env e){
        requireInvariant addressSetInvariant(representative, chainId);
      }
    }


// setup self check - reachability of currentContract external functions
rule method_reachability {
  env e;
  calldataarg arg;
  method f;

  f(e, arg);
  satisfy true;
}
