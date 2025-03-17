// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {EthereumPayload, PayloadArgs as EthereumPayloadArgs} from '../../src/payloads/Ethereum.sol';
import {PolygonPayload, PayloadArgs as PolygonPayloadArgs} from '../../src/payloads/Polygon.sol';
import {AvalanchePayload, PayloadArgs as AvalanchePayloadArgs} from '../../src/payloads/Avalanche.sol';
import {Create2Utils} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import '../GovBaseScript.sol';

abstract contract BaseMerklePayloadUpdates is GovBaseScript {
  function getCreationCode() internal view virtual returns (bytes memory);
  function getEncodedParams() internal view virtual returns (bytes memory);
  function getPayloadSalt() internal view virtual returns (bytes32);

  function getPayload() internal returns (address) {
    bytes memory code = getCreationCode();
    bytes memory encodedParams = getEncodedParams();
    bytes memory payloadBytecode = abi.encodePacked(code, encodedParams);

    return
      Create2Utils.create2Deploy(
        keccak256(abi.encode(getPayloadSalt())),
        payloadBytecode
      );
  }

  function _execute(GovDeployerHelpers.Addresses memory) internal override {
    address payload = getPayload();
  }
}

contract Ethereum is BaseMerklePayloadUpdates {
  function getCreationCode() internal pure override returns (bytes memory) {
    return type(EthereumPayload).creationCode;
  }

  function getEncodedParams() internal pure override returns (bytes memory) {
    return
      abi.encode(
        EthereumPayloadArgs({
          eth_eth_voting_portal: 0x6ACe1Bf22D57a33863161bFDC851316Fb0442690,
          eth_avax_voting_portal: 0x9Ded9406f088C10621BE628EEFf40c1DF396c172,
          eth_pol_voting_portal: 0xFe4683C18aaad791B6AFDF0a8e1Ed5C6e2c9ecD6,
          cross_chain_controller: 0xEd42a7D8559a463722Ca4beD50E0Cc05a386b0e1,
          governance: 0x9AEE0B04504CeF83A65AC3f0e838D0593BCb2BC7,
          voting_machine: 0x06a1795a88b82700896583e123F46BE43877bFb6
        })
      );
  }

  function getPayloadSalt() internal pure override returns (bytes32) {
    return keccak256(bytes('Merkle payload updates for Ethereum'));
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Polygon is BaseMerklePayloadUpdates {
  function getCreationCode() internal pure override returns (bytes memory) {
    return type(PolygonPayload).creationCode;
  }

  function getEncodedParams() internal pure override returns (bytes memory) {
    return
      abi.encode(
        PolygonPayloadArgs({
          cross_chain_controller: 0xF6B99959F0b5e79E1CC7062E12aF632CEb18eF0d,
          voting_machine: 0x44c8b753229006A8047A05b90379A7e92185E97C
        })
      );
  }

  function getPayloadSalt() internal pure override returns (bytes32) {
    return keccak256(bytes('Merkle payload updates for Polygon'));
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Avalanche is BaseMerklePayloadUpdates {
  function getCreationCode() internal pure override returns (bytes memory) {
    return type(AvalanchePayload).creationCode;
  }

  function getEncodedParams() internal pure override returns (bytes memory) {
    return
      abi.encode(
        AvalanchePayloadArgs({
          cross_chain_controller: 0x27FC7D54C893dA63C0AE6d57e1B2B13A70690928,
          voting_machine: 0x4D1863d22D0ED8579f8999388BCC833CB057C2d6
        })
      );
  }

  function getPayloadSalt() internal pure override returns (bytes32) {
    return keccak256(bytes('Merkle payload updates for Avalanche'));
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}
