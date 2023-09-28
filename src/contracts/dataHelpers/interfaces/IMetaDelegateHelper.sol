// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGovernancePowerDelegationToken} from 'aave-token-v3/interfaces/IGovernancePowerDelegationToken.sol';

/**
 * @title IMetaDelegateHelper
 * @author BGD Labs
 * @notice Interface containing the methods for the batch governance power delegation across multiple voting assets
 */

interface IMetaDelegateHelper {
  enum DelegationType {
    VOTING,
    PROPOSITION,
    ALL
  }

  /**
   * @notice an object including parameters for the delegation change
   * @param underlyingAsset the asset the governance power of which delegator wants to delegate
   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION, ALL)
   * @param delegator the owner of the funds
   * @param delegatee the user to who owner delegates his governance power
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  struct MetaDelegateParams {
    IGovernancePowerDelegationToken underlyingAsset;
    DelegationType delegationType;
    address delegator;
    address delegatee;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @notice method for the batch upgrade governance power delegation across multiple voting assets with signatures
   * @param delegateParams an array with signatures with the user and assets to interact with
   */
  function batchMetaDelegate(MetaDelegateParams[] calldata delegateParams)
    external;
}
