// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGovernancePowerDelegationToken} from 'aave-token-v3/interfaces/IGovernancePowerDelegationToken.sol';
import {IMetaDelegateHelper} from './interfaces/IMetaDelegateHelper.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title MetaDelegateHelper
 * @author BGD Labs
 * @notice The helper contract for the batch governance power delegation across multiple voting assets
 */
contract MetaDelegateHelper is IMetaDelegateHelper {
  /// @inheritdoc IMetaDelegateHelper
  function batchMetaDelegate(
    MetaDelegateParams[] calldata delegateParams
  ) external {
    bool atLeastOnePassed = false;

    for (uint256 i = 0; i < delegateParams.length; i++) {
      if (delegateParams[i].delegationType == DelegationType.ALL) {
        try
          delegateParams[i].underlyingAsset.metaDelegate(
            delegateParams[i].delegator,
            delegateParams[i].delegatee,
            delegateParams[i].deadline,
            delegateParams[i].v,
            delegateParams[i].r,
            delegateParams[i].s
          )
        {
          atLeastOnePassed = true;
        } catch {}
      } else {
        try
          delegateParams[i].underlyingAsset.metaDelegateByType(
            delegateParams[i].delegator,
            delegateParams[i].delegatee,
            delegateParams[i].delegationType == DelegationType.VOTING
              ? IGovernancePowerDelegationToken.GovernancePowerType.VOTING
              : IGovernancePowerDelegationToken.GovernancePowerType.PROPOSITION,
            delegateParams[i].deadline,
            delegateParams[i].v,
            delegateParams[i].r,
            delegateParams[i].s
          )
        {
          atLeastOnePassed = true;
        } catch {}
      }
    }
    require(atLeastOnePassed, Errors.ALL_DELEGATION_ACTIONS_FAILED);
  }
}
