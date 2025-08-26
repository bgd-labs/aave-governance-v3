// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';

struct PayloadArgs {
  address cross_chain_controller;
  address voting_machine;
}

contract PolygonPayload {
  address public immutable CROSS_CHAIN_CONTROLLER;
  address public immutable VOTING_MACHINE;

  constructor(PayloadArgs memory args) {
    CROSS_CHAIN_CONTROLLER = args.cross_chain_controller;
    VOTING_MACHINE = args.voting_machine;
  }

  function execute() external {
    // set voting machine as approved sender for cross chain controller
    address[] memory sendersToApprove = new address[](1);
    sendersToApprove[0] = VOTING_MACHINE;
    ICrossChainForwarder(CROSS_CHAIN_CONTROLLER).approveSenders(sendersToApprove);
  }
}