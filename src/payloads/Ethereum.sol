// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {IGovernanceCore} from '../interfaces/IGovernanceCore.sol';

struct PayloadArgs {
  address eth_eth_voting_portal;
  address eth_avax_voting_portal;
  address eth_pol_voting_portal;
  address cross_chain_controller;
  address governance;
  address voting_machine;
}

contract EthereumPayload {
  address public immutable ETH_ETH_VOTING_PORTAL;
  address public immutable ETH_AVAX_VOTING_PORTAL;
  address public immutable ETH_POL_VOTING_PORTAL;
  address public immutable CROSS_CHAIN_CONTROLLER;
  address public immutable GOVERNANCE;
  address public immutable VOTING_MACHINE;

  constructor(PayloadArgs memory args) {
    ETH_ETH_VOTING_PORTAL = args.eth_eth_voting_portal;
    ETH_AVAX_VOTING_PORTAL = args.eth_avax_voting_portal;
    ETH_POL_VOTING_PORTAL = args.eth_pol_voting_portal;
    CROSS_CHAIN_CONTROLLER = args.cross_chain_controller;
    GOVERNANCE = args.governance;
    VOTING_MACHINE = args.voting_machine;
  }

  function execute() external {
    // set voting machine and voting portals as approved senders for cross chain controller
    address[] memory sendersToApprove = new address[](4);
    sendersToApprove[0] = VOTING_MACHINE;
    sendersToApprove[1] = ETH_ETH_VOTING_PORTAL;
    sendersToApprove[2] = ETH_AVAX_VOTING_PORTAL;
    sendersToApprove[3] = ETH_POL_VOTING_PORTAL;
    ICrossChainForwarder(CROSS_CHAIN_CONTROLLER).approveSenders(sendersToApprove);

    // set voting portals on governance
    address[] memory votingPortals = new address[](3);
    votingPortals[0] = ETH_ETH_VOTING_PORTAL;
    votingPortals[1] = ETH_AVAX_VOTING_PORTAL;
    votingPortals[2] = ETH_POL_VOTING_PORTAL;
    IGovernanceCore(GOVERNANCE).addVotingPortals(votingPortals);
  }
}