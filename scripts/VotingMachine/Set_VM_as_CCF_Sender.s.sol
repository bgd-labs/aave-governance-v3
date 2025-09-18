// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseSetCCFApprovedSenders} from '../baseCCC/Set_CCF_Approved_Senders.s.sol';
import '../GovBaseScript.sol';

contract Ethereum is BaseSetCCFApprovedSenders {
  function getSendersToApprove()
    public
    view
    override
    returns (address[] memory)
  {
    GovDeployerHelpers.Addresses memory addresses = GovDeployerHelpers
      .getAddresses(TRANSACTION_NETWORK(), vm);
    address[] memory sendersToApprove = new address[](2);
    sendersToApprove[0] = addresses.votingMachine;
    sendersToApprove[1] = addresses.governance;

    return sendersToApprove;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Avalanche is BaseSetCCFApprovedSenders {
  function getSendersToApprove()
    public
    view
    override
    returns (address[] memory)
  {
    GovDeployerHelpers.Addresses memory addresses = GovDeployerHelpers
      .getAddresses(TRANSACTION_NETWORK(), vm);
    address[] memory sendersToApprove = new address[](1);
    sendersToApprove[0] = addresses.votingMachine;

    return sendersToApprove;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Polygon is BaseSetCCFApprovedSenders {
  function getSendersToApprove()
    public
    view
    override
    returns (address[] memory)
  {
    GovDeployerHelpers.Addresses memory addresses = GovDeployerHelpers
      .getAddresses(TRANSACTION_NETWORK(), vm);
    address[] memory sendersToApprove = new address[](1);
    sendersToApprove[0] = addresses.votingMachine;

    return sendersToApprove;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Binance is BaseSetCCFApprovedSenders {
  function getSendersToApprove()
    public
    view
    override
    returns (address[] memory)
  {
    GovDeployerHelpers.Addresses memory addresses = GovDeployerHelpers
      .getAddresses(TRANSACTION_NETWORK(), vm);
    address[] memory sendersToApprove = new address[](1);
    sendersToApprove[0] = addresses.votingMachine;

    return sendersToApprove;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}
