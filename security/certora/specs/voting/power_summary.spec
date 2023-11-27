/// ============================================================================
/// `VotingMachine` contract - setup with `getVotingPower` summary
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

    // `VotingStrategy` ========================================================
    function VotingStrategyHarness.AAVE() external returns (address) envfree;
    function VotingStrategyHarness.A_AAVE() external returns (address) envfree;
    function VotingStrategyHarness.STK_AAVE() external returns (address) envfree;
    function VotingStrategyHarness.getVotingAssetListLength(
    ) external returns (uint256) envfree;
    function VotingStrategyHarness.isTokenSlotAccepted(
        address, uint128
    ) external returns (bool) envfree;
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
    ) external =>
    _getVotingPower(asset, baseStorageSlot, power, blockHash) expect (uint256);
  
    // `DataWarehouse` =========================================================
    // Summarized since it retrieves data from slots
    function DataWarehouse.getStorage(
        address account,
        bytes32 blockHash,
        bytes32 slot,
        bytes storageProof
    ) external returns (StateProofVerifier.SlotValue) =>
    _getStorage(account, blockHash, slot, storageProof);

    // `CrossChainController` ==================================================
    // NOTE: Not clear why this call is not resolved, we summarize it as `NONDET`
    // NOTE: Not a view method - not a safe summary! 20231120 Trying without
    //function CrossChainController.forwardMessage(
    //    uint256, address, uint256, bytes
    //) external returns (bytes32,bytes32) => NONDET;

    // `SlotUtils` =============================================================
    // Summarized for speed-up
    function SlotUtils.getAccountSlotHash(
        address, uint256
    ) internal returns (bytes32) => NONDET;
}


/// `getStorage` summary =======================================================
/** @title Storage mapping
 * @param underlyingAsset
 * @param storageProof
 * @return raw voting power for the given asset
 */
ghost mapping(address => mapping(bytes => uint256)) _slotValues;


/// @title Summary of `DataWarehouse.getStorage` - slot always exists
function _getStorage(
    address account,  // proof.underlyingAsset
    bytes32 blockHash,
    bytes32 slot,
    bytes storageProof
) returns StateProofVerifier.SlotValue {
    StateProofVerifier.SlotValue slotval;
    require slotval.exists;
    require slotval.value == _slotValues[account][storageProof];
    return slotval;
}


/// Voting power summary =======================================================

/* The method `getVotingPower` is summarized in `_getVotingPower` below.
 * To keep fixed values per voter and asset, we use the ghost mapping `_votingAssetPower`.
 */


/** @title Voting power mapping
 * Note: use `mockVotingPower` to get a voter's voting power, do not use the mapping
 * directly.
 * @param power: power of voter
 * @param asset: address of asset
 * @param baseStorageSlot
 * @return voter's voting power for the given asset
 */
ghost mapping(uint256 => mapping(address => mapping(uint128 => uint256))) _votingAssetPower;


/** @title Mock voting power
 * @param asset: address of asset
 * @param baseStorageSlot: slot to use for the asset
 * @param power: power (balance) of voter
 * @return `_votingAssetPower[power][asset][baseStorageSlot]` if asset is one of 
 *  `AAVE`, `STK_AAVE` or `A_AAVE`, and has the appropriate slot, and power is non-zero,
 *  zero otherwise
 */
function mockVotingPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power
) returns uint256 {
    // Return 0 if asset is not one of `AAVE`, `A_AAVE` or `STK_AAVE`
    if (
        asset != _VotingStrategy.AAVE() &&
        asset != _VotingStrategy.STK_AAVE() &&
        asset != _VotingStrategy.A_AAVE()) {
        return 0;
    }
    if (power == 0) {
        return 0;
    }
    return (
        _VotingStrategy.isTokenSlotAccepted(asset, baseStorageSlot) ?
        _votingAssetPower[power][asset][baseStorageSlot] : 0
    );
}


/// @title Summary of `VotingStrategy.getVotingPower`
function _getVotingPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power,
    bytes32 blockHash
) returns uint256 {
    uint256 votingPower = mockVotingPower(asset, baseStorageSlot, power);
    return votingPower;
}


// Code mock verification rules ================================================

/** @title There are exactly three acceptable tokens
 *  @notice This invariant fails sanity due to due being tautological, i.e.:
 *  "trivial invariant check FAILED: post-state assertion is trivially true".
 *  It is kept since many configs and rules are based on this property, and
 *  therefore should be retained in CI.
 */
invariant onlyThreeTokens()
    _VotingStrategy.getVotingAssetListLength() == 3;


// setup self check - reachability of currentContract external functions
rule method_reachability {
  env e;
  calldataarg arg;
  method f;

  f(e, arg);
  satisfy true;
}

