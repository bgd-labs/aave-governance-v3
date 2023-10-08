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
    // NOTE: Not clear why this call is not resolved, we summarize it as `NONDET`
    function CrossChainController.forwardMessage(
        uint256, address, uint256, bytes
    ) external returns (bytes32,bytes32) => NONDET;

    // `SlotUtils` =============================================================
    // Summarized for speed-up
    function SlotUtils.getAccountSlotHash(
        address, uint256
    ) internal returns (bytes32) => NONDET;
}
