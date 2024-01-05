// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {MockGovernance, IMockGovernance} from '../extendedContracts/MockGovernance.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {AaveV3Ethereum, AaveV3Sepolia} from 'aave-address-book/AaveAddressBook.sol';

abstract contract BaseDeployMockGovernance is GovBaseScript {
  function getExecutionGasLimit() public view virtual returns (uint256) {
    return 300_000;
  }

  function getAddressesToAllow() public view virtual returns (address[] memory);

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    DeployerHelpers.Addresses memory ccAddresses = _getCCAddresses(
      TRANSACTION_NETWORK()
    );

    MockGovernance mockGov = new MockGovernance(
      ccAddresses.crossChainController,
      getExecutionGasLimit(),
      addresses.owner,
      getAddressesToAllow()
    );

    require(
      mockGov.getAllowedAddresses()[0] == addresses.owner,
      'Incorrect settings'
    );

    addresses.mockGovernance = address(mockGov);
  }
}

contract Ethereum is BaseDeployMockGovernance {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function getAddressesToAllow()
    public
    view
    override
    returns (address[] memory)
  {
    address[] memory addressesToAllow = new address[](1);
    GovDeployerHelpers.Addresses memory addresses = _getAddresses(
      TRANSACTION_NETWORK()
    );

    addressesToAllow[0] = addresses.owner;

    return addressesToAllow;
  }
}
