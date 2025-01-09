// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {ITransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {Errors} from '../../src/contracts/libraries/Errors.sol';
import {Governance, IGovernance} from '../../src/contracts/Governance.sol';
import {IGovernanceCore, PayloadsControllerUtils} from 'aave-address-book/GovernanceV3.sol';
import {IWithGuardian} from 'solidity-utils/contracts/access-control/interfaces/IWithGuardian.sol';

contract Governance_V3_Test is Test {
  uint256 constant GAS_LIMIT = 300_000;

  IGovernance govV3_Impl;

  uint256 currentProposalCount;

  function setUp() public {
    vm.createSelectFork('ethereum', 18820742);

    govV3_Impl = new Governance(
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      0,
      address(AaveV3Ethereum.COLLECTOR)
    );

    hoax(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ProxyAdmin(MiscEthereum.PROXY_ADMIN).upgradeAndCall(
      ITransparentUpgradeableProxy(
        payable(address(GovernanceV3Ethereum.GOVERNANCE))
      ),
      address(govV3_Impl),
      abi.encodeWithSelector(
        IGovernance.initializeWithRevision.selector,
        GAS_LIMIT
      )
    );
  }

  function test_initialize() public {
    assertEq(
      IGovernance(address(GovernanceV3Ethereum.GOVERNANCE))
        .CROSS_CHAIN_CONTROLLER(),
      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER
    );
    assertEq(
      IGovernance(address(GovernanceV3Ethereum.GOVERNANCE)).getGasLimit(),
      GAS_LIMIT
    );
    require(
      GovernanceV3Ethereum.GOVERNANCE.CANCELLATION_FEE_COLLECTOR() !=
        address(0),
      'WRONG FEE COLLECTOR'
    );
    assertEq(GovernanceV3Ethereum.GOVERNANCE.COOLDOWN_PERIOD(), 0);
    assertEq(
      Ownable(address(GovernanceV3Ethereum.GOVERNANCE)).owner(),
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );
  }

  function test_old_storage() public {
    assertEq(GovernanceV3Ethereum.GOVERNANCE.getProposalsCount(), 0);
    assertEq(
      address(GovernanceV3Ethereum.GOVERNANCE.getPowerStrategy()),
      GovernanceV3Ethereum.GOVERNANCE_POWER_STRATEGY
    );
    assertEq(GovernanceV3Ethereum.GOVERNANCE.getProposalsCount(), 0);
    assertEq(GovernanceV3Ethereum.GOVERNANCE.getCancellationFee(), 0.05 ether);
    IGovernanceCore.VotingConfig memory votingConfigLvl1 = GovernanceV3Ethereum
      .GOVERNANCE
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    assertEq(votingConfigLvl1.coolDownBeforeVotingStart, 1 days);
    assertEq(votingConfigLvl1.votingDuration, 3 days);
    assertEq(votingConfigLvl1.yesThreshold, 320_000);
    assertEq(votingConfigLvl1.yesNoDifferential, 80_000);
    assertEq(votingConfigLvl1.minPropositionPower, 80_000);

    IGovernanceCore.VotingConfig memory votingConfigLvl2 = GovernanceV3Ethereum
      .GOVERNANCE
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_2);

    assertEq(votingConfigLvl2.coolDownBeforeVotingStart, 1 days);
    assertEq(votingConfigLvl2.votingDuration, 10 days);
    assertEq(votingConfigLvl2.yesThreshold, 1_040_000);
    assertEq(votingConfigLvl2.yesNoDifferential, 1_040_000);
    assertEq(votingConfigLvl2.minPropositionPower, 200_000);

    assertEq(
      GovernanceV3Ethereum.GOVERNANCE.isVotingPortalApproved(
        GovernanceV3Ethereum.VOTING_PORTAL_ETH_ETH
      ),
      true
    );
    assertEq(
      GovernanceV3Ethereum.GOVERNANCE.isVotingPortalApproved(
        GovernanceV3Ethereum.VOTING_PORTAL_ETH_AVAX
      ),
      true
    );
    assertEq(
      GovernanceV3Ethereum.GOVERNANCE.isVotingPortalApproved(
        GovernanceV3Ethereum.VOTING_PORTAL_ETH_POL
      ),
      true
    );
  }
}
