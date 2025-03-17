// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {EthereumPayload, PayloadArgs as EthereumPayloadArgs} from '../../src/payloads/ethereum.sol';
import {PolygonPayload, PayloadArgs as PolygonPayloadArgs} from '../../src/payloads/polygon.sol';
import {AvalanchePayload, PayloadArgs as AvalanchePayloadArgs} from '../../src/payloads/avalanche.sol';
import {Create2Utils} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import '../GovBaseScript.sol';

contract BaseMerklePayloadUpdates is GovBaseScript {
  function getCreationCode() internal view virtual returns (bytes memory);
  function getEncodedParams(
    GovDeployerHelpers.Addresses memory addresses
  ) internal view virtual returns (bytes memory);
  function getPayloadSalt() internal view virtual returns (bytes32);

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    bytes memory code = getCreationCode();
    bytes memory encodedParams = getEncodedParams(addresses);

    bytes memory payloadBytecode = abi.encodePacked(code, encodedParams);

    address payload = Create2Utils.create2Deploy(
      keccak256(abi.encode(getPayloadSalt())),
      payloadBytecode
    );
  }
}

contract Ethereum {
  function getCreationCode() internal view override returns (bytes memory) {
    return type(EthereumPayload).creationCode;
  }

  function getEncodedParams(
    GovDeployerHelpers.Addresses memory addresses
  ) internal view override returns (bytes memory) {
    CCCAddresses memory ccAddresses = _getCCAddresses(TRANSACTION_NETWORK());

    return
      abi.encode(
        EthereumPayloadArgs({
          eth_eth_voting_portal: addresses.votingPortal_Eth_Eth,
          eth_avax_voting_portal: addresses.votingPortal_Eth_Avax,
          eth_pol_voting_portal: addresses.votingPortal_Eth_Pol,
          cross_chain_controller: ccAddresses.crossChainController,
          governance: addresses.governance,
          voting_machine: addresses.votingMachine
        })
      );
  }

  function getPayloadSalt() internal view override returns (bytes32) {
    return keccak256(bytes('Merkle payload updates for Ethereum'));
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Polygon is BaseMerklePayloadUpdates {
  function getCreationCode() internal view override returns (bytes memory) {
    return type(PolygonPayload).creationCode;
  }

  function getEncodedParams(
    GovDeployerHelpers.Addresses memory addresses
  ) internal view override returns (bytes memory) {
    CCCAddresses memory ccAddresses = _getCCAddresses(TRANSACTION_NETWORK());

    return
      abi.encode(
        PolygonPayloadArgs({
          cross_chain_controller: ccAddresses.crossChainController,
          voting_machine: addresses.votingMachine
        })
      );
  }

  function getPayloadSalt() internal view override returns (bytes32) {
    return keccak256(bytes('Merkle payload updates for Polygon'));
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Avalanche is BaseMerklePayloadUpdates {
  function getCreationCode() internal view override returns (bytes memory) {
    return type(AvalanchePayload).creationCode;
  }

  function getEncodedParams(
    GovDeployerHelpers.Addresses memory addresses
  ) internal view override returns (bytes memory) {
    CCCAddresses memory ccAddresses = _getCCAddresses(TRANSACTION_NETWORK());

    return
      abi.encode(
        AvalanchePayloadArgs({
          cross_chain_controller: ccAddresses.crossChainController,
          voting_machine: addresses.votingMachine
        })
      );
  }

  function getPayloadSalt() internal view override returns (bytes32) {
    return keccak256(bytes('Merkle payload updates for Avalanche'));
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}
