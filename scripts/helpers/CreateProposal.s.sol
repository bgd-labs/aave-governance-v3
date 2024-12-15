// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import '../../src/interfaces/IGovernanceCore.sol';

abstract contract BaseCreateProposal is GovBaseScript {
  function getPayloads()
    public
    view
    virtual
    returns (PayloadsControllerUtils.Payload[] memory);

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    bytes32 ipfsHash = bytes32(abi.encode(''));
    uint256 proposalId = IGovernanceCore(
      0x2B2fa1A67964613F8056FB8612494893A2B90DCa
    ).createProposal(getPayloads(), addresses.votingPortal_Eth_Pol, ipfsHash);

    console.log('proposalId', proposalId);
  }
}

contract Ethereum_testnet is BaseCreateProposal {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }

  function getPayloads()
    public
    view
    override
    returns (PayloadsControllerUtils.Payload[] memory)
  {
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](1);
    payloads[0] = PayloadsControllerUtils.Payload({
      chain: TestNetChainIds.POLYGON_AMOY,
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      payloadsController: _getAddresses(TestNetChainIds.POLYGON_AMOY)
        .payloadsController,
      payloadId: 7
    });

    return payloads;
  }
}
