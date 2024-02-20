// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {IMockGovernance, PayloadsControllerUtils} from '../extendedContracts/MockGovernance.sol';

abstract contract BaseBridgeExecutionMessage is GovBaseScript {
  function DESTINATION_NETWORK() public view virtual returns (uint256);

  function getDestinationPayloadId() public view virtual returns (uint40);

  function getMessage() public view virtual returns (bytes memory) {
    return abi.encode('some random message');
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    GovDeployerHelpers.Addresses memory destinationAddresses = _getAddresses(
      DESTINATION_NETWORK()
    );

    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        chain: destinationAddresses.chainId,
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        payloadsController: destinationAddresses.payloadsController,
        payloadId: getDestinationPayloadId()
      });
    uint40 proposalVoteActivationTimestamp = uint40(block.timestamp);

    IMockGovernance(addresses.mockGovernance).forwardPayloadForExecution(
      payload,
      proposalVoteActivationTimestamp
    );
  }
}

contract Ethereum is BaseBridgeExecutionMessage {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function DESTINATION_NETWORK() public pure override returns (uint256) {
    return ChainIds.CELO;
  }

  function getDestinationPayloadId() public pure override returns (uint40) {
    return uint40(0);
  }
}
