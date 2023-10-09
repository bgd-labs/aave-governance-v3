pragma solidity ^0.8.0;

import {AaveTokenV3} from 'aave-token-v3/AaveTokenV3.sol';

contract AaveTokenV3_DummyA is AaveTokenV3 {

  function getDelegatedPowerByTypeHarness(
    address user,
    GovernancePowerType delegationType
  ) public returns (uint256) {
    DelegationState memory userState = _getDelegationState(user);
    return  _getDelegatedPowerByType(userState, delegationType);
  }
}
