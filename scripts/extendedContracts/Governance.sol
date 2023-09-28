// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Governance} from '../../src/contracts/Governance.sol';
import {IGovernanceCore} from '../../src/interfaces/IGovernanceCore.sol';

contract GovernanceExtended is Governance {
  /**
   * @param crossChainController address of current network message controller (cross chain controller or same chain controller)
   * @param coolDownPeriod time that should pass before proposal will be moved to vote, in seconds
   */
  constructor(
    address crossChainController,
    uint256 coolDownPeriod,
    address cancellationFeeCollector
  )
    Governance(crossChainController, coolDownPeriod, cancellationFeeCollector)
  {}

  // @inheritdoc IGovernanceCore
  function ACHIEVABLE_VOTING_PARTICIPATION()
    public
    pure
    override
    returns (uint256)
  {
    return 5_000_000 ether;
  }

  // @inheritdoc IGovernanceCore
  function MIN_VOTING_DURATION() public pure override returns (uint256) {
    return 0;
  }
}
