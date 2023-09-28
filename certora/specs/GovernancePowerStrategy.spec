// Verification of `GovernancePowerStrategy` contract ==========================
using AaveTokenV3_DummyA as _DummyTokenA;
using AaveTokenV3_DummyB as _DummyTokenB;
using AaveTokenV3_DummyC as _DummyTokenC;


methods
{
    // IBaseVotingStrategy =====================================================
    function AAVE() external returns (address) envfree;
    function A_AAVE() external returns (address) envfree;
    function STK_AAVE() external returns (address) envfree;
    function BASE_BALANCE_SLOT() external returns (uint128) envfree;
    function A_AAVE_BASE_BALANCE_SLOT() external returns (uint128) envfree;
    function A_AAVE_DELEGATED_STATE_SLOT() external returns (uint128) envfree;

    function isTokenSlotAccepted(address, uint128) external returns (bool) envfree;
    function getVotingAssetList() external returns (address[]) envfree;
    function getVotingAssetConfig(address) external returns (
        IBaseVotingStrategy.VotingAssetConfig
    ) envfree;
    function getFullVotingPower(address) external returns (uint256) envfree;
    function getFullPropositionPower(address) external returns (uint256) envfree;

    // AaveTokenV3 =============================================================
    function AaveTokenV3_DummyA.getPowerCurrent(
        address,
        IGovernancePowerDelegationToken.GovernancePowerType
    ) external returns (uint256) envfree;
    function AaveTokenV3_DummyA.getDelegateeByType(
        address,
        IGovernancePowerDelegationToken.GovernancePowerType
    ) external returns (address) envfree;

    function AaveTokenV3_DummyB.getPowerCurrent(
        address,
        IGovernancePowerDelegationToken.GovernancePowerType
    ) external returns (uint256) envfree;

    function AaveTokenV3_DummyC.getPowerCurrent(
        address,
        IGovernancePowerDelegationToken.GovernancePowerType
    ) external returns (uint256) envfree;

    function _.getPowerCurrent(
        address,
        IGovernancePowerDelegationToken.GovernancePowerType
    ) external => DISPATCHER(true);
}


// Utils =======================================================================

/// @title Each dummy token is a unique and accepted token
function eachDummyIsUniqueToken() {
    // Tokens are unique
    require (
        _DummyTokenA != _DummyTokenB &&
        _DummyTokenA != _DummyTokenC &&
        _DummyTokenB != _DummyTokenC
    );

    // Tokens are accepted
    uint128 slotA;
    uint128 slotB;
    uint128 slotC;
    require (
        isTokenSlotAccepted(_DummyTokenA, slotA) &&
        isTokenSlotAccepted(_DummyTokenB, slotB) &&
        isTokenSlotAccepted(_DummyTokenC, slotC)
    );
}


/// @title Return the value of the correct power type
function _getPower(
    address voter,
    IGovernancePowerDelegationToken.GovernancePowerType govType
) returns uint256 {
    return (
        govType == IGovernancePowerDelegationToken.GovernancePowerType.VOTING ?
        getFullVotingPower(voter) :
        getFullPropositionPower(voter)
    );
}


// Rules =======================================================================

/// @title Invalid token or slot is refused - a unittest
rule invalidTokenRefused(address token, uint128 slot) {
    require (
        (token != AAVE() || slot != BASE_BALANCE_SLOT()) &&
        (token != STK_AAVE() || slot != BASE_BALANCE_SLOT()) &&
        (
            token != A_AAVE() ||
            (slot != A_AAVE_BASE_BALANCE_SLOT() && slot != A_AAVE_DELEGATED_STATE_SLOT())
        )
    );
    assert !isTokenSlotAccepted(token, slot);
}


/// @title No power in each token implies no power at all
rule powerlessCompliance(
    address voter,
    IGovernancePowerDelegationToken.GovernancePowerType govType
) {
    eachDummyIsUniqueToken();
    require (
        _DummyTokenA.getPowerCurrent(voter, govType) == 0 &&
        _DummyTokenB.getPowerCurrent(voter, govType) == 0 &&
        _DummyTokenC.getPowerCurrent(voter, govType) == 0
    );

    assert _getPower(voter, govType) == 0;
}


/** @title Transferring does not raise the power of the sender nor lowers the power of
 *  the receiver, except in specific cases
 */
rule transferPowerCompliance(
    address voter,
    address another,
    uint256 amount,
    IGovernancePowerDelegationToken.GovernancePowerType govType
) {
    require (
        voter != _DummyTokenA && voter != another && another != _DummyTokenA
    );
    eachDummyIsUniqueToken();

    // `voter`'s power can increase if `another` delegated its power to `voter`
    address delegatee = _DummyTokenA.getDelegateeByType(another, govType);

    uint256 prePowerVoter = _getPower(voter, govType);
    uint256 prePowerAnother = _getPower(another, govType);

    env e;
    require e.msg.sender == voter;
    _DummyTokenA.transfer(e, another, amount);

    uint256 postPowerVoter = _getPower(voter, govType);
    uint256 postPowerAnother = _getPower(another, govType);

    assert (amount == 0) => (
        postPowerVoter == prePowerVoter && postPowerAnother == prePowerAnother
    );
    assert (amount > 0) => (
        (postPowerVoter > prePowerVoter) => (
            delegatee == voter &&
            postPowerAnother <= prePowerAnother
        ) &&
        (delegatee == 0) => (postPowerAnother > prePowerAnother)
    );
}


/** @title Delegating does not increase the power of the delegator, nor reduce the
 *  power of the new delegatee.
 *
 *  @notice This rule cannot include a strict inequality. The reason is that
 *  the delegated power in `AaveTokenV3` is saved as rounded down balance,
 *  see `BaseDelegation._governancePowerTransferByType` (dividing by `POWER_SCALE_FACTOR`
 *  when setting the delegated power field and multiplying by it when extracting).
 *  This causes violations when trying to assert propositions such as:
 *      (postPowerNewDelegatee > prePowerNewDelegatee) <=> 
 *      (postPowerCurDelegatee < prePowerCurDelegatee)
 */
rule delegatePowerCompliance(
    address voter,
    address newDelegatee,
    IGovernancePowerDelegationToken.GovernancePowerType govType
) {
    require (
        voter != 0 &&
        voter != _DummyTokenA &&
        voter != newDelegatee &&
        newDelegatee != 0 &&
        newDelegatee != _DummyTokenA
    );
    eachDummyIsUniqueToken();

    uint256 prePowerVoter = _getPower(voter, govType);
    uint256 prePowerNewDelegatee = _getPower(newDelegatee, govType);

    // The current delegatee is zero if there is none
    address getDelegRes = _DummyTokenA.getDelegateeByType(voter, govType);
    address curDelegatee = getDelegRes == 0 ? voter : getDelegRes;
    uint256 prePowerCurDelegatee = _getPower(curDelegatee, govType);
    require newDelegatee != curDelegatee;

    env e;
    require e.msg.sender == voter;
    _DummyTokenA.delegateByType(e, newDelegatee, govType);

    uint256 postPowerVoter = _getPower(voter, govType);
    uint256 postPowerNewDelegatee = _getPower(newDelegatee, govType);
    uint256 postPowerCurDelegatee = _getPower(curDelegatee, govType);

    assert (
        postPowerVoter <= prePowerVoter &&
        postPowerNewDelegatee >= prePowerNewDelegatee &&
        postPowerCurDelegatee <= prePowerCurDelegatee
    );
}
