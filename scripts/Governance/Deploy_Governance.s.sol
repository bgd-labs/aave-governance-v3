// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {Governance} from '../../src/contracts/Governance.sol';
import {IGovernance, IGovernanceCore} from '../../src/interfaces/IGovernance.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {AaveV3Ethereum, AaveV3Sepolia} from 'aave-address-book/AaveAddressBook.sol';

import {GovernanceExtended} from '../extendedContracts/Governance.sol';

abstract contract BaseDeployGovernance is GovBaseScript {
  function getVotingConfigurations()
    public
    view
    virtual
    returns (IGovernanceCore.SetVotingConfigInput[] memory);

  function isTest() public view virtual returns (bool) {
    return false;
  }

  function getCoolDownPeriod() public view virtual returns (uint256) {
    return 0;
  }

  function getExecutionGasLimit() public view virtual returns (uint256) {
    return 180_000;
  }

  function getCancellationFee() public view virtual returns (uint256) {
    return 0.05 ether;
  }

  function getCancellationFeeCollector() public view virtual returns (address);

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigs = getVotingConfigurations();

    DeployerHelpers.Addresses memory ccAddresses = _getCCAddresses(
      TRANSACTION_NETWORK()
    );

    // deploy governance.
    IGovernance governanceImpl;
    if (isTest()) {
      governanceImpl = new GovernanceExtended(
        ccAddresses.crossChainController,
        getCoolDownPeriod(),
        getCancellationFeeCollector()
      );
    } else {
      governanceImpl = new Governance(
        ccAddresses.crossChainController,
        getCoolDownPeriod(),
        getCancellationFeeCollector()
      );
    }

    //    addresses.governance = TransparentProxyFactory(ccAddresses.proxyFactory)
    //      .createDeterministic(
    //        address(governanceImpl),
    //        ccAddresses.proxyAdmin,
    //        abi.encodeWithSelector(
    //          IGovernance.initialize.selector,
    //          addresses.owner,
    //          addresses.guardian,
    //          addresses.governancePowerStrategy,
    //          votingConfigs,
    //          new address[](0), // voting portals
    //          getExecutionGasLimit(),
    //          getCancellationFee()
    //        ),
    //        Constants.GOVERNANCE_SALT
    //      );

    addresses.governanceImpl = address(governanceImpl);
  }
}

contract Ethereum is BaseDeployGovernance {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function getCancellationFeeCollector()
    public
    pure
    override
    returns (address)
  {
    return address(AaveV3Ethereum.COLLECTOR);
  }

  function getVotingConfigurations()
    public
    pure
    override
    returns (IGovernanceCore.SetVotingConfigInput[] memory)
  {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigs = new IGovernanceCore.SetVotingConfigInput[](2);

    IGovernanceCore.SetVotingConfigInput memory level1Config = IGovernanceCore
      .SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        coolDownBeforeVotingStart: 1 days,
        votingDuration: 3 days,
        yesThreshold: 320_000 ether,
        yesNoDifferential: 80_000 ether,
        minPropositionPower: 50_000 ether
      });
    votingConfigs[0] = level1Config;

    IGovernanceCore.SetVotingConfigInput memory level2Config = IGovernanceCore
      .SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        coolDownBeforeVotingStart: 1 days,
        votingDuration: 7 days, //64000,
        yesThreshold: 1_400_000 ether,
        yesNoDifferential: 1_400_000 ether,
        minPropositionPower: 80_000 ether
      });
    votingConfigs[1] = level2Config;

    return votingConfigs;
  }
}

contract Ethereum_testnet is BaseDeployGovernance {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }

  function getCancellationFeeCollector()
    public
    pure
    override
    returns (address)
  {
    return address(AaveV3Sepolia.COLLECTOR);
  }

  function isTest() public pure override returns (bool) {
    return true;
  }

  function getVotingConfigurations()
    public
    pure
    override
    returns (IGovernanceCore.SetVotingConfigInput[] memory)
  {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigs = new IGovernanceCore.SetVotingConfigInput[](2);

    IGovernanceCore.SetVotingConfigInput memory level1Config = IGovernanceCore
      .SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        coolDownBeforeVotingStart: 600,
        votingDuration: 600,
        yesThreshold: 200,
        yesNoDifferential: 50,
        minPropositionPower: 5 ether
      });
    votingConfigs[0] = level1Config;

    IGovernanceCore.SetVotingConfigInput memory level2Config = IGovernanceCore
      .SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        coolDownBeforeVotingStart: 800,
        votingDuration: 800,
        yesThreshold: 2000 ether,
        yesNoDifferential: 1000 ether,
        minPropositionPower: 2000 ether
      });
    votingConfigs[1] = level2Config;

    return votingConfigs;
  }
}
