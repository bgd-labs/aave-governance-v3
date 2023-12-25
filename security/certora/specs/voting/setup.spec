/// ============================================================================
/// `VotingMachine` contract - basic setup
/// ============================================================================
using VotingStrategyHarness as _VotingStrategy;


methods
{
    // `VotingMachine` =========================================================
    function getUserProposalVote(
        address, uint256
    ) external returns (IVotingMachineWithProofs.Vote) envfree;

    function getProposalById(
        uint256
    ) external returns (IVotingMachineWithProofs.ProposalWithoutVotes) envfree;

    function getProposalVoteConfiguration(
        uint256
    ) external returns (IVotingMachineWithProofs.ProposalVoteConfiguration) envfree;

    function getIdOfProposal(uint256) external returns (uint256) envfree;

    function getProposalsVoteConfigurationIds(
        uint256, uint256
    ) external returns (uint256[] memory) envfree;

    // `VotingStrategy` ========================================================
    function VotingStrategyHarness.is_hasRequiredRoots(
        bytes32
    ) external returns (bool) envfree;

    // `getVotingPower` is summarized since it uses bitwise operations and retrieves
    // data from slots. We use a wildcard since it is called as:
    // `IVotingStrategy(address(VOTING_STRATEGY)).getVotingPower`
    function _.getVotingPower(
        address asset,
        uint128 baseStorageSlot,
        uint256 power,
        bytes32 blockHash
    ) external => NONDET;
  
    // `DataWarehouse` =========================================================
    // Summarized since it retrieves data from slots
    function DataWarehouse.getStorage(
        address account,
        bytes32 blockHash,
        bytes32 slot,
        bytes storageProof
    ) external returns (StateProofVerifier.SlotValue) => NONDET;

    // `CrossChainController` ==================================================
    // NOTE: Summarized since it contains a `delegatecall` in `CrossChainForwarder.sol`
    // Line 284
    // NOTE: This is not a view function, so `NONDET` summary is not safe!
    function CrossChainController.forwardMessage(
        uint256, address, uint256, bytes
    ) external returns (bytes32,bytes32) => NONDET;

    // `SlotUtils` =============================================================
    // Summarized for speed-up
    function SlotUtils.getAccountSlotHash(
        address, uint256
    ) internal returns (bytes32) => NONDET;
}


// Defines methods that usually must be filtered out from invariants and parametric rules
definition filteredMethods(method f) returns bool = (
    // Filtered due to unresolved call from `Address.sol` Line 136:
    // `target.call{value: value}(data)`
    // f.selector != sig:CrossChainController.emergencyTokenTransfer(
    //     address, address, uint256
    // ).selector &&

    // Filtered due to unresolved call from `CrossChainReceiver.sol` Line 231:
    // `IBaseReceiverPortal(envelope.destination).receiveCrossChainMessage(`
    // `   envelope.origin,envelope.originChainId,envelope.message`
    // `)`
    //f.selector != sig:receiveCrossChainMessage(address,uint256,bytes).selector &&

    // Filtered due to unresolved call from `CrossChainReceiver.sol` Line 231: see above
    // f.selector != sig:CrossChainController.deliverEnvelope(
    //     CrossChainController.Envelope
    // ).selector &&

    // Filtered due to unresolved call from `Rescuable.sol` Line 3:
    // to.call{value: amount}(new bytes(0))
    // f.selector != sig:CrossChainController.emergencyEtherTransfer(
    //     address,uint256
    // ).selector &&

    // Filtered due to unresolved call from `Address.sol` Line 189:
    // `target.delegatecall(data)`
    // f.selector != sig:CrossChainController.enableBridgeAdapters(
    //     ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[]
    // ).selector  &&

    // Unreachable methods
    // NOTE: It is unclear why these are unreachable in 6.0.0
    // f.selector != sig:CrossChainController.isEnvelopeRegistered(
    //     CrossChainController.Envelope
    // ).selector &&
    f.selector != sig:CrossChainController.retryEnvelope(
        CrossChainController.Envelope, uint256
    ).selector &&
    // f.selector != sig:CrossChainController.receiveCrossChainMessage(
    //     bytes, uint256
    // ).selector &&
    // f.selector != sig:CrossChainController.getEnvelopeState(
    //     CrossChainController.Envelope
    // ).selector &&
    f.selector != sig:CrossChainController.forwardMessage(
        uint256, address, uint256, bytes
    ).selector &&
    f.selector != sig:CrossChainController.retryTransaction(
        bytes, uint256, address[]
    ).selector &&
    f.selector != sig:CrossChainController.initialize(
        address,
        address,
        ICrossChainReceiver.ConfirmationInput[],
        ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[],
        ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[],
        address[]
    ).selector
);


// setup self check - reachability of currentContract external functions
rule method_reachability(method f) filtered {
    f -> filteredMethods(f)
} {
  env e;
  calldataarg arg;
  f(e, arg);
  satisfy true;
}
