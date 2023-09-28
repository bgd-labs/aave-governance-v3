// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IGovernanceCore} from '../../src/interfaces/IGovernanceCore.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import '../GovBaseScript.sol';

abstract contract BaseGovernanceSetVotingConfig is GovBaseScript {
  function getVotingDuration() public view virtual returns (uint24);

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);
    // access level 2 (short executor) configuration
    IGovernanceCore.SetVotingConfigInput memory level12Config = IGovernanceCore
      .SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        coolDownBeforeVotingStart: 400,
        votingDuration: getVotingDuration(),
        yesThreshold: 200 ether,
        yesNoDifferential: 50 ether,
        minPropositionPower: 125 ether
      });

    votingConfigs[0] = level12Config;

    IGovernanceCore(addresses.governance).setVotingConfigs(votingConfigs);
  }
}

contract Ethereum is BaseGovernanceSetVotingConfig {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function getVotingDuration() public pure override returns (uint24) {
    return 3600;
  }
}

contract Ethereum_testnet is BaseGovernanceSetVotingConfig {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }

  function getVotingDuration() public pure override returns (uint24) {
    return 3600;
  }
}
