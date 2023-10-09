/* Setup for `VotingStrategy` contract =========================================
 * Since we can't really verify `VotingStrategy.getWeightedPower` (which is the main
 * method), we opted for some "unit tests".
 *
 * TODO:
 * - Still missing unit tests for delegated power!
 * - General rules, e.g. voting power is monotonic increasing with balance ...
 */
using DelegationModeHarness as _Delegation;


methods
{
    // VotingStrategy ==========================================================
    function AAVE() external returns (address) envfree;
    function A_AAVE() external returns (address) envfree;
    function STK_AAVE() external returns (address) envfree;
    function STK_AAVE_SLASHING_EXCHANGE_RATE_PRECISION() external returns (uint256) envfree;
    function POWER_SCALE_FACTOR() external returns (uint256) envfree;
    function BASE_BALANCE_SLOT() external returns (uint128) envfree;
    function A_AAVE_BASE_BALANCE_SLOT() external returns (uint128) envfree;
    function A_AAVE_DELEGATED_STATE_SLOT() external returns (uint128) envfree;

    function isTokenSlotAccepted(address, uint128) external returns (bool) envfree;

    // DataWarehouse ===========================================================
    function DataWarehouse.getRegisteredSlot(
        bytes32 blockHash,
        address account,
        bytes32 slot
    ) external returns (uint256) => _getRegisteredSlot(blockHash, account, slot);
    
    // DelegationModeHarness ===================================================
    function DelegationModeHarness.is_equal_to_original() external returns (bool) envfree;
    function DelegationModeHarness.mode_to_int(
        DelegationModeHarness.Mode
    ) external returns (uint8) envfree;
}


// Summarize `getRegisteredSlot` ===============================================
ghost mapping(address => uint256) _exchangeRateSlotValue;

/**
 * @title Summarize `getRegisteredSlot`
 * The summary is intended to be used for calculating `exchangeRateSlotValue`, as
 * constant per asset (=account).
 */
function _getRegisteredSlot(
    bytes32 blockHash,
    address account,
    bytes32 slot
) returns uint256 {
    return _exchangeRateSlotValue[account];
}


// Utilities ===================================================================
function constructPower(
    address asset,
    uint120 balance,
    uint72 delegated,
    DelegationModeHarness.Mode delegation,
    uint128 slot
) returns uint256 {
    // Only `A_AAVE` uses `uint120` as balance, the others use `uint104`
    require asset != A_AAVE() => balance <= max_uint104;

    // The delegation mode is the highest 8 bits of `power`
    uint8 delegationMode = _Delegation.mode_to_int(delegation);
    mathint power = balance + (2^(256 - 8)) * delegationMode;
    return isTokenSlotAccepted(asset, slot) ?  assert_uint256(power) : 0;
}


// Test `DelegationMode` hack ==================================================

/** @title Verify that `DelegationModeHarness.Mode` equals `DelegationMode`
 *
 * @notice The reason for using `DelegationModeHarness.Mode` in the first place is
 * that `DelegationMode` is an enum that is not part of any contract. So it cannot be
 * used inside the spec. Therefore I created `DelegationModeHarness` that has
 * an enum `DelegationModeHarness.Mode` that is supposed to be equal to the original
 * `DelegationMode`. This spec uses `DelegationModeHarness.Mode`, and this rule
 * verifies that it is equal to `DelegationMode`.
 */
rule delegationModeHackTest() {
    assert _Delegation.is_equal_to_original(), "DelegationMode changed";
}


// Unit-tests for `getVotingPower` =============================================

/// @title Zero power implies zero voting power
rule zeroPowerIsZeroVotingPower(
    address asset,
    uint128 baseStorageSlot,
    bytes32 blockHash
) {
    env e;
    uint256 votingPower = getVotingPower(e, asset, baseStorageSlot, 0, blockHash);
    assert votingPower == 0, "Non-zero voting power despite power being zero";
}


/// @title Undelegated balance is roughly voting power (for `AAVE` and `A_AAVE`)
rule UnDelegatedBalanceIsPower_AAVE_A_AAVE(
    address asset,
    bytes32 blockHash,
    uint120 balance,
    DelegationModeHarness.Mode delegation
) {
    require asset == AAVE() || asset == A_AAVE();
    require (
        delegation != DelegationModeHarness.Mode.VOTING_DELEGATED &&
        delegation != DelegationModeHarness.Mode.FULL_POWER_DELEGATED
    ); // Voter's balance is not delegated for voting

    uint128 storageSlot = (
        (asset == AAVE()) ? BASE_BALANCE_SLOT() : A_AAVE_BASE_BALANCE_SLOT()
    );
    uint256 raw_power = constructPower(asset, balance, 0, delegation, storageSlot);

    env e;
    uint256 votingPower = getVotingPower(e, asset, storageSlot, raw_power, blockHash);

    uint256 calc_power = require_uint256(balance);
    assert votingPower == calc_power, "Undelegated balance != power in AAVE/A_AAVE";
}


/// @title Formula for voting power given only undelegated balance in `STK_AAVE`
rule UnDelegatedBalancePower_STK_AAVE(
    bytes32 blockHash,
    uint104 balance,
    DelegationModeHarness.Mode delegation
) {
    address asset = STK_AAVE();
    require (
        delegation != DelegationModeHarness.Mode.VOTING_DELEGATED &&
        delegation != DelegationModeHarness.Mode.FULL_POWER_DELEGATED
    ); // Voter's balance is not delegated for voting
    uint256 raw_power = constructPower(
        asset, balance, 0, delegation, BASE_BALANCE_SLOT()
    );
    // The code uses only the `uint216` part of the slot, the require below
    // allows us to use the same value.
    uint256 exchangeRate = require_uint216(_exchangeRateSlotValue[asset]);

    env e;
    uint256 votingPower = getVotingPower(
        e, asset, BASE_BALANCE_SLOT(), raw_power, blockHash
    );

    mathint calculated = (
        (balance * STK_AAVE_SLASHING_EXCHANGE_RATE_PRECISION()) / exchangeRate
    );
    uint256 calc_power = assert_uint256(calculated);
    assert votingPower == calc_power, "Undelegated balance != power in STK_AAVE";
}


/// @title Wrong slot yields zero power
rule wrongSlotYieldsZeroPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power,
    bytes32 blockHash
) {
    require !isTokenSlotAccepted(asset, baseStorageSlot);

    env e;
    uint256 votingPower = getVotingPower(e, asset, baseStorageSlot, power, blockHash);
    assert votingPower == 0, "Non-zero voting power despite wrong baseStorageSlot";
}


/// @title Wrong asset yields zero power
rule wrongAssetYieldsZeroPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power,
    bytes32 blockHash
) {
    require asset != AAVE() && asset != A_AAVE() && asset != STK_AAVE();

    env e;
    uint256 votingPower = getVotingPower(e, asset, baseStorageSlot, power, blockHash);
    assert votingPower == 0, "Non-zero voting power despite wrong asset";
}
