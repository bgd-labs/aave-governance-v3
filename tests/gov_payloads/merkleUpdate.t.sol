// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovV3Helpers} from 'aave-helpers/GovV3Helpers.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {Ethereum, Polygon, Avalanche} from '../../scripts/GovernancePayloads/MerklePayloadUpdates.s.sol';
import {EthereumPayload} from '../../src/payloads/ethereum.sol';
import {IGovernanceCore} from '../../src/interfaces/IGovernanceCore.sol';
import '../../scripts/GovBaseScript.sol';

abstract contract BaseMerklePayloadUpdatesTest is Test {
  address internal _payload;
  address internal _crossChainController;

  string internal NETWORK;
  uint256 internal immutable BLOCK_NUMBER;

  function _getPayloadToTest() internal virtual returns (address);

  constructor(string memory network, uint256 blockNumber) {
    NETWORK = network;
    BLOCK_NUMBER = blockNumber;
  }

  function executePayload(Vm vm, address payload) internal {
    GovV3Helpers.executePayload(vm, payload);
  }

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl(NETWORK), BLOCK_NUMBER);

    _payload = _getPayloadToTest();
  }
  // ------------------------ tests --------------------------------//
  function test_vm_set() public {
    // check that vm address in payload is not set in ccc
    bool vmIsApprovedBefore = ICrossChainForwarder(
      EthereumPayload(_payload).CROSS_CHAIN_CONTROLLER()
    ).isSenderApproved(EthereumPayload(_payload).VOTING_MACHINE());

    assertFalse(vmIsApprovedBefore);

    // execute payload
    executePayload(vm, _payload);

    // check that vm address in payload is set in ccc
    bool vmIsApprovedAfter = ICrossChainForwarder(
      EthereumPayload(_payload).CROSS_CHAIN_CONTROLLER()
    ).isSenderApproved(EthereumPayload(_payload).VOTING_MACHINE());

    assertTrue(vmIsApprovedAfter);
  }
}

contract EthereumMerklePayloadTest is
  Ethereum,
  BaseMerklePayloadUpdatesTest('ethereum', 22066545)
{
  function _getPayloadToTest() internal override returns (address) {
    return getPayload();
  }

  function test_vp_set_on_governance() public {
    // check that vp is not set on governance
    bool vp_Eth_Eth_IsSet_Before = IGovernanceCore(
      EthereumPayload(_payload).GOVERNANCE()
    ).isVotingPortalApproved(EthereumPayload(_payload).ETH_ETH_VOTING_PORTAL());
    bool vp_Eth_Avax_IsSet_Before = IGovernanceCore(
      EthereumPayload(_payload).GOVERNANCE()
    ).isVotingPortalApproved(
        EthereumPayload(_payload).ETH_AVAX_VOTING_PORTAL()
      );
    bool vp_Eth_Pol_IsSet_Before = IGovernanceCore(
      EthereumPayload(_payload).GOVERNANCE()
    ).isVotingPortalApproved(EthereumPayload(_payload).ETH_POL_VOTING_PORTAL());

    assertFalse(vp_Eth_Eth_IsSet_Before);
    assertFalse(vp_Eth_Avax_IsSet_Before);
    assertFalse(vp_Eth_Pol_IsSet_Before);

    // execute payload
    executePayload(vm, _payload);

    // check that vp is set on governance
    bool vp_Eth_Eth_IsSet_After = IGovernanceCore(
      EthereumPayload(_payload).GOVERNANCE()
    ).isVotingPortalApproved(EthereumPayload(_payload).ETH_ETH_VOTING_PORTAL());
    bool vp_Eth_Avax_IsSet_After = IGovernanceCore(
      EthereumPayload(_payload).GOVERNANCE()
    ).isVotingPortalApproved(
        EthereumPayload(_payload).ETH_AVAX_VOTING_PORTAL()
      );
    bool vp_Eth_Pol_IsSet_After = IGovernanceCore(
      EthereumPayload(_payload).GOVERNANCE()
    ).isVotingPortalApproved(EthereumPayload(_payload).ETH_POL_VOTING_PORTAL());

    assertTrue(vp_Eth_Eth_IsSet_After);
    assertTrue(vp_Eth_Avax_IsSet_After);
    assertTrue(vp_Eth_Pol_IsSet_After);
  }

  function test_vp_set_on_ccc() public {
    // check that vp is set on ccc
    bool vp_Eth_Eth_IsSet_Before = ICrossChainForwarder(
      EthereumPayload(_payload).CROSS_CHAIN_CONTROLLER()
    ).isSenderApproved(EthereumPayload(_payload).ETH_ETH_VOTING_PORTAL());
    bool vp_Eth_Avax_IsSet_Before = ICrossChainForwarder(
      EthereumPayload(_payload).CROSS_CHAIN_CONTROLLER()
    ).isSenderApproved(EthereumPayload(_payload).ETH_AVAX_VOTING_PORTAL());
    bool vp_Eth_Pol_IsSet_Before = ICrossChainForwarder(
      EthereumPayload(_payload).CROSS_CHAIN_CONTROLLER()
    ).isSenderApproved(EthereumPayload(_payload).ETH_POL_VOTING_PORTAL());

    assertFalse(vp_Eth_Eth_IsSet_Before);
    assertFalse(vp_Eth_Avax_IsSet_Before);
    assertFalse(vp_Eth_Pol_IsSet_Before);

    // execute payload
    executePayload(vm, _payload);

    // check that vm address in payload is set in ccc
    bool vp_Eth_Eth_IsSet_After = ICrossChainForwarder(
      EthereumPayload(_payload).CROSS_CHAIN_CONTROLLER()
    ).isSenderApproved(EthereumPayload(_payload).ETH_ETH_VOTING_PORTAL());
    bool vp_Eth_Avax_IsSet_After = ICrossChainForwarder(
      EthereumPayload(_payload).CROSS_CHAIN_CONTROLLER()
    ).isSenderApproved(EthereumPayload(_payload).ETH_AVAX_VOTING_PORTAL());
    bool vp_Eth_Pol_IsSet_After = ICrossChainForwarder(
      EthereumPayload(_payload).CROSS_CHAIN_CONTROLLER()
    ).isSenderApproved(EthereumPayload(_payload).ETH_POL_VOTING_PORTAL());

    assertTrue(vp_Eth_Eth_IsSet_After);
    assertTrue(vp_Eth_Avax_IsSet_After);
    assertTrue(vp_Eth_Pol_IsSet_After);
  }
}

contract PolygonMerklePayloadTest is
  Polygon,
  BaseMerklePayloadUpdatesTest('polygon', 69159381)
{
  function _getPayloadToTest() internal override returns (address) {
    return getPayload();
  }
}

contract AvalancheMerklePayloadTest is
  Avalanche,
  BaseMerklePayloadUpdatesTest('avalanche', 58849591)
{
  function _getPayloadToTest() internal override returns (address) {
    return getPayload();
  }
}
