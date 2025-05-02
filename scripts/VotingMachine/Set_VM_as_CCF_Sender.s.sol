// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseSetCCFApprovedSenders} from 'adi-deploy/scripts/ccc/Set_CCF_Approved_Senders.s.sol';
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

  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
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

  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
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

  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
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

  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Ethereum_testnet is BaseSetCCFApprovedSenders {
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

  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Avalanche_testnet is BaseSetCCFApprovedSenders {
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

  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Polygon_testnet is BaseSetCCFApprovedSenders {
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

  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return TestNetChainIds.POLYGON_AMOY;
  }
}

contract Binance_testnet is BaseSetCCFApprovedSenders {
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

  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}
