// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import '../GovBaseScript.sol';

/**
 * @notice This script needs to be implemented from where the senders are known
 */
abstract contract BaseSetCCFApprovedSenders is GovBaseScript {
  function getSendersToApprove() public virtual returns (address[] memory);

  function _execute(GovDeployerHelpers.Addresses memory addresses) internal override {
    ICrossChainForwarder(addresses.crossChainController).approveSenders(getSendersToApprove());
  }
}
