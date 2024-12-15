// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DelegationMode} from './../../../src/contracts/voting/VotingStrategy.sol';

/**
 * @title Hack to use DelegationMode in spec
 * `DelegationMode` is not part of any contract, and so cannot be used in spec,
 * this hack solves the problem by providing enum `Mode` which is equal.
 */
contract DelegationModeHarness {
  enum Mode {
    NO_DELEGATION,
    VOTING_DELEGATED,
    PROPOSITION_DELEGATED,
    FULL_POWER_DELEGATED
  }

  function is_equal_to_original() public view returns (bool) {
    return (uint8(type(Mode).min) == uint8(type(DelegationMode).min) &&
      uint8(type(Mode).max) == uint8(type(DelegationMode).max) &&
      uint8(Mode.NO_DELEGATION) == uint8(DelegationMode.NO_DELEGATION) &&
      uint8(Mode.VOTING_DELEGATED) == uint8(DelegationMode.VOTING_DELEGATED) &&
      uint8(Mode.PROPOSITION_DELEGATED) ==
      uint8(DelegationMode.PROPOSITION_DELEGATED) &&
      uint8(Mode.FULL_POWER_DELEGATED) ==
      uint8(DelegationMode.FULL_POWER_DELEGATED));
  }

  function mode_to_int(Mode mode) public view returns (uint8) {
    return uint8(mode);
  }
}
