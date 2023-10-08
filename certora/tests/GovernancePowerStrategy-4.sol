// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGovernancePowerDelegationToken} from 'aave-token-v3/interfaces/IGovernancePowerDelegationToken.sol';
import {IBaseVotingStrategy} from '../interfaces/IBaseVotingStrategy.sol';
import {IGovernancePowerStrategy} from '../interfaces/IGovernancePowerStrategy.sol';
import {BaseVotingStrategy} from './BaseVotingStrategy.sol';

/**
 * @title GovernancePowerStrategy
 * @author BGD Labs
 * @notice This contracts overrides the base voting strategy to return the power of specific assets used on the strategy.
  * @dev These tokens will be used to get the proposition power to check if proposal can be created, and are the ones
         needed on the voting machine chain voting strategy.
 */
contract GovernancePowerStrategy is
  BaseVotingStrategy,
  IGovernancePowerStrategy
{
  /// @inheritdoc IGovernancePowerStrategy
  function getFullVotingPower(address user) external view returns (uint256) {
    return
      _getFullPowerByType(
        user,
        IGovernancePowerDelegationToken.GovernancePowerType.VOTING
      );
  }

  /// @inheritdoc IGovernancePowerStrategy
  function getFullPropositionPower(
    address user
  ) external view returns (uint256) {
    return
      _getFullPowerByType(
        user,
        IGovernancePowerDelegationToken.GovernancePowerType.PROPOSITION
      );
  }

  /**
   * @notice method to get the full user's power by type
   * @param user address of the user to get the full power
   * @param powerType type of the power to get (voting, proposal)
   * @return full power of an user depending on the type (voting, proposal)
   */
  function _getFullPowerByType(
    address user,
    IGovernancePowerDelegationToken.GovernancePowerType powerType
  ) internal view returns (uint256) {
    uint256 fullGovernancePower;

    address[] memory votingAssetList = getVotingAssetList();
    for (uint256 i = 0; i < votingAssetList.length-1; i++) {
      fullGovernancePower += IGovernancePowerDelegationToken(votingAssetList[i])
        .getPowerCurrent(user, powerType);
    }

    return fullGovernancePower;
  }
}
