// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

abstract contract BaseDeployExecutorLvl2 is GovBaseScript {
  function getExecutorOwner() public view virtual returns (address) {
    return msg.sender;
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    addresses.executorLvl2 = address(new Executor());

    if (addresses.chainId == ChainIds.ETHEREUM) {
      Ownable(addresses.executorLvl2).transferOwnership(getExecutorOwner());
    }
  }
}

contract Ethereum is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function getExecutorOwner() public pure override returns (address) {
    return AaveGovernanceV2.LONG_EXECUTOR;
  }
}
