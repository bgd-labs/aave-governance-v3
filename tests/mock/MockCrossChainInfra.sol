// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {CrossChainController} from 'aave-delivery-infrastructure/contracts/CrossChainController.sol';
import {ChainIds} from 'aave-delivery-infrastructure/contracts/libs/ChainIds.sol';
import {LayerZeroAdapter} from 'aave-delivery-infrastructure/contracts/adapters/layerZero/LayerZeroAdapter.sol';
import {PayloadsController} from '../../src/contracts/payloads/PayloadsController.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';
import {CrossChainTestPayload} from './Payload.sol';

contract MockToImport {
  constructor() {
    new CrossChainController();

    new LayerZeroAdapter(
      address(0),
      address(0),
      0,
      new LayerZeroAdapter.TrustedRemotesConfig[](0)
    );
    new Executor();
    new PayloadsController(address(0), address(0), ChainIds.AVALANCHE);
    new CrossChainTestPayload();
  }
}
