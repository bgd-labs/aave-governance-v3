// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {GovernanceCore} from '../src/contracts/GovernanceCore.sol';
import {Governance, IGovernance, IGovernanceCore, PayloadsControllerUtils} from '../src/contracts/Governance.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {IGovernancePowerStrategy} from '../src/interfaces/IGovernancePowerStrategy.sol';
import {IVotingPortal} from '../src/interfaces/IVotingPortal.sol';
import {IVotingMachineWithProofs} from '../src/contracts/voting/interfaces/IVotingMachineWithProofs.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {Errors} from '../src/contracts/libraries/Errors.sol';
import {IBaseVotingStrategy} from '../src/interfaces/IBaseVotingStrategy.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';

contract GCore_VotingConfigsTest is Test {
  address public constant OWNER = address(65536 + 123);
  address public constant GUARDIAN = address(65536 + 1234);
  address public constant ADMIN = address(65536 + 12345);
  address public constant CROSS_CHAIN_CONTROLLER = address(123456);
  address public constant SAME_CHAIN_VOTING_MACHINE = address(1234567);
  address public constant EXECUTION_PORTAL = address(12345678);
  address public constant VOTING_STRATEGY = address(123456789);
  address public constant VOTING_PORTAL = address(1230123);
  address public constant CANCELLATION_FEE_COLLECTOR = address(123404321);
  uint256 public constant EXECUTION_GAS_LIMIT = 400000;
  uint256 public constant COOLDOWN_PERIOD = 1 days;
  uint256 public constant ACHIEVABLE_VOTING_PARTICIPATION = 5_000_000 ether;

  uint256 public CURRENT_CHAIN_ID;
  bytes32 public constant GOVERNANCE_CORE_SALT =
    keccak256('governance core salt');

  //  IGovernanceCore public governance;
  IGovernanceCore public governanceImpl;
  TransparentProxyFactory public proxyFactory;

  event VotingConfigUpdated(
    PayloadsControllerUtils.AccessControl indexed accessLevel,
    uint24 votingDuration,
    uint24 coolDownBeforeVotingStart,
    uint256 yesThreshold,
    uint256 yesNoDifferential,
    uint256 minPropositionPower
  );

  struct InputConfigs {
    IGovernanceCore.SetVotingConfigInput l1;
    IGovernanceCore.SetVotingConfigInput l2;
    IGovernanceCore.SetVotingConfigInput[] arr;
  }

  function _getDefaultConfInput() internal pure returns (InputConfigs memory) {
    InputConfigs memory configs;
    configs.l1 = IGovernanceCore.SetVotingConfigInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      votingDuration: uint24(7 days),
      coolDownBeforeVotingStart: uint24(1 days),
      yesThreshold: 320_000 ether,
      yesNoDifferential: 100_000 ether,
      minPropositionPower: 50_000 ether
    });

    configs.l2 = IGovernanceCore.SetVotingConfigInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
      votingDuration: uint24(7 days),
      coolDownBeforeVotingStart: uint24(1 days),
      yesThreshold: configs.l1.yesThreshold + 320_000 ether,
      yesNoDifferential: configs.l1.yesNoDifferential + 100_000 ether,
      minPropositionPower: configs.l1.minPropositionPower + 50_000 ether
    });
    configs.arr = new IGovernanceCore.SetVotingConfigInput[](2);
    configs.arr[0] = configs.l1;
    configs.arr[1] = configs.l2;
    return configs;
  }

  function setUp() public {
    proxyFactory = new TransparentProxyFactory();

    governanceImpl = new Governance(
      CROSS_CHAIN_CONTROLLER,
      COOLDOWN_PERIOD,
      CANCELLATION_FEE_COLLECTOR
    );
  }

  function testInitialize() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    InputConfigs memory configs = _getDefaultConfInput();

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    address[] memory powerTokens = new address[](1);
    powerTokens[0] = address(1239746519);

    //-------------------------------------------
    //         call
    // ------------------------------------------
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(IBaseVotingStrategy.getVotingAssetList.selector),
      abi.encode(powerTokens)
    );
    IGovernanceCore governance = IGovernanceCore(
      proxyFactory.createDeterministic(
        address(governanceImpl),
        ProxyAdmin(ADMIN),
        abi.encodeWithSelector(
          IGovernance.initialize.selector,
          OWNER,
          GUARDIAN,
          VOTING_STRATEGY,
          configs.arr,
          votingPortals,
          EXECUTION_GAS_LIMIT
        ),
        GOVERNANCE_CORE_SALT
      )
    );
    //-------------------------------------------
    //         asserts
    // ------------------------------------------

    _validateConfigsLvl1(configs.l1, governance);
    _validateConfigsLvl2(configs.l2, governance);
  }

  function testInitializeWhenMissingVotingConfigs() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](0);

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    address[] memory powerTokens = new address[](1);
    powerTokens[0] = address(1239746519);

    //-------------------------------------------
    //         call
    // ------------------------------------------

    vm.expectRevert(bytes(Errors.MISSING_VOTING_CONFIGURATIONS));
    IGovernanceCore(
      proxyFactory.createDeterministic(
        address(governanceImpl),
        ProxyAdmin(ADMIN),
        abi.encodeWithSelector(
          IGovernance.initialize.selector,
          OWNER,
          GUARDIAN,
          VOTING_STRATEGY,
          votingConfigsInput,
          votingPortals,
          EXECUTION_GAS_LIMIT
        ),
        GOVERNANCE_CORE_SALT
      )
    );
  }

  function testSetVotingConfigsLv1Lv2() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();
    InputConfigs memory configs = _getDefaultConfInput();

    hoax(OWNER);
    governance.setVotingConfigs(configs.arr);
    //-------------------------------------------
    //         asserts
    // ------------------------------------------

    _validateConfigsLvl1(configs.l1, governance);
    _validateConfigsLvl2(configs.l2, governance);
  }

  function testSetVotingConfigsLvl1WhenYesThresholdOfL1BiggerThenL2() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();
    InputConfigs memory configs = _getDefaultConfInput();

    configs.l1.yesThreshold = configs.l2.yesThreshold + 1 ether;

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = configs.l1;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_YES_THRESHOLD));
    governance.setVotingConfigs(votingConfigsInput);
  }

  function testSetVotingConfigsLvl1WhenYesThresholdOfIsBiggerThenAchievableVotes(
    uint8 levelModifier,
    uint248 extraParticipation
  ) public {
    vm.assume(extraParticipation >= 1 ether);
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();
    InputConfigs memory configs = _getDefaultConfInput();

    configs.arr[levelModifier % 2].yesThreshold =
      governance.ACHIEVABLE_VOTING_PARTICIPATION() +
      extraParticipation;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_YES_THRESHOLD));
    governance.setVotingConfigs(configs.arr);
  }

  function testSetVotingConfigsLvl1WhenYesThresholdOfL2SmallerThenL1() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();
    InputConfigs memory configs = _getDefaultConfInput();

    configs.l2.yesThreshold = configs.l1.yesThreshold - 1;

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = configs.l2;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_YES_THRESHOLD));
    governance.setVotingConfigs(votingConfigsInput);
  }

  function testSetVotingConfigsLvl1WhenDiffTooBig(
    uint256 wrongYesNoDifferential
  ) public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();
    vm.assume(
      wrongYesNoDifferential > governance.ACHIEVABLE_VOTING_PARTICIPATION()
    );

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl1 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: 320_000 ether,
        yesNoDifferential: wrongYesNoDifferential,
        minPropositionPower: 50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigInputLvl1;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_YES_NO_DIFFERENTIAL));
    governance.setVotingConfigs(votingConfigsInput);
  }

  function testSetVotingConfigsLvl1WhenPowerTooBig() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();

    IGovernanceCore.VotingConfig memory votingConfigL2 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_2);

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl1 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: 320_000 ether,
        yesNoDifferential: 100_000 ether,
        minPropositionPower: votingConfigL2.minPropositionPower *
          governance.PRECISION_DIVIDER() +
          1 ether
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigInputLvl1;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_PROPOSITION_POWER));
    governance.setVotingConfigs(votingConfigsInput);
  }

  //----
  function testSetVotingConfigsLv2WhenYesThresholdTooLow() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();

    IGovernanceCore.VotingConfig memory votingConfigL1 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl2 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: votingConfigL1.yesThreshold *
          governance.PRECISION_DIVIDER() -
          2 ether,
        yesNoDifferential: votingConfigL1.yesNoDifferential *
          governance.PRECISION_DIVIDER() +
          100_000 ether,
        minPropositionPower: votingConfigL1.minPropositionPower *
          governance.PRECISION_DIVIDER() +
          50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigInputLvl2;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_YES_THRESHOLD));
    governance.setVotingConfigs(votingConfigsInput);
  }

  function testSetVotingConfigsLv2WhenYesThresholdTooBig(
    uint256 yesThresholdExtra
  ) public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();
    vm.assume(
      yesThresholdExtra != 0 &&
        type(uint256).max - yesThresholdExtra >
        governance.ACHIEVABLE_VOTING_PARTICIPATION()
    );

    IGovernanceCore.VotingConfig memory votingConfigL1 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl2 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: governance.ACHIEVABLE_VOTING_PARTICIPATION() +
          yesThresholdExtra,
        yesNoDifferential: votingConfigL1.yesNoDifferential *
          governance.PRECISION_DIVIDER() +
          100_000 ether,
        minPropositionPower: votingConfigL1.minPropositionPower *
          governance.PRECISION_DIVIDER() +
          50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigInputLvl2;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_YES_THRESHOLD));
    governance.setVotingConfigs(votingConfigsInput);
  }

  function testSetVotingConfigsLv2WhenDiffTooLow() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();

    IGovernanceCore.VotingConfig memory votingConfigL1 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl2 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: votingConfigL1.yesThreshold *
          governance.PRECISION_DIVIDER() +
          320_000 ether,
        yesNoDifferential: votingConfigL1.yesNoDifferential *
          governance.PRECISION_DIVIDER() -
          1 ether,
        minPropositionPower: votingConfigL1.minPropositionPower *
          governance.PRECISION_DIVIDER() +
          50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigInputLvl2;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_YES_NO_DIFFERENTIAL));
    governance.setVotingConfigs(votingConfigsInput);
  }

  function testSetVotingConfigsLv2WhenDiffTooBig(
    uint256 yesNoDifferentialExtra
  ) public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();
    vm.assume(
      yesNoDifferentialExtra != 0 &&
        type(uint256).max - yesNoDifferentialExtra >
        governance.ACHIEVABLE_VOTING_PARTICIPATION()
    );

    IGovernanceCore.VotingConfig memory votingConfigL1 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl2 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: votingConfigL1.yesThreshold *
          governance.PRECISION_DIVIDER() +
          320_000 ether,
        yesNoDifferential: governance.ACHIEVABLE_VOTING_PARTICIPATION() +
          yesNoDifferentialExtra,
        minPropositionPower: votingConfigL1.minPropositionPower *
          governance.PRECISION_DIVIDER() +
          50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigInputLvl2;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_YES_NO_DIFFERENTIAL));
    governance.setVotingConfigs(votingConfigsInput);
  }

  function testSetVotingConfigsLv2WhenPowerTooLow() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();

    IGovernanceCore.VotingConfig memory votingConfigL1 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl2 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: votingConfigL1.yesThreshold *
          governance.PRECISION_DIVIDER() +
          320_000 ether,
        yesNoDifferential: votingConfigL1.yesNoDifferential *
          governance.PRECISION_DIVIDER() +
          100_000 ether,
        minPropositionPower: votingConfigL1.minPropositionPower *
          governance.PRECISION_DIVIDER() -
          1 ether
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigInputLvl2;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_PROPOSITION_POWER));
    governance.setVotingConfigs(votingConfigsInput);
  }

  function testSetVotingConfigsLv2WhenPowerTooBig(
    uint256 propositionExtra
  ) public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();
    vm.assume(
      propositionExtra != 0 &&
        type(uint256).max - propositionExtra >
        governance.ACHIEVABLE_VOTING_PARTICIPATION()
    );

    IGovernanceCore.VotingConfig memory votingConfigL1 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl2 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: votingConfigL1.yesThreshold *
          governance.PRECISION_DIVIDER() +
          320_000 ether,
        yesNoDifferential: votingConfigL1.yesNoDifferential *
          governance.PRECISION_DIVIDER() +
          100_000 ether,
        minPropositionPower: governance.ACHIEVABLE_VOTING_PARTICIPATION() +
          propositionExtra
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigInputLvl2;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_PROPOSITION_POWER));
    governance.setVotingConfigs(votingConfigsInput);
  }

  function testSetVotingConfigsNotOrdered() public {
    //-------------------------------------------
    // configuration
    // ------------------------------------------
    IGovernanceCore governance = _initialize();

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl1 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: 320_000 ether,
        yesNoDifferential: 100_000 ether,
        minPropositionPower: 50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl2 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: votingConfigInputLvl1.yesThreshold + 320_000 ether,
        yesNoDifferential: votingConfigInputLvl1.yesNoDifferential +
          100_000 ether,
        minPropositionPower: votingConfigInputLvl1.minPropositionPower +
          50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](2);
    votingConfigsInput[1] = votingConfigInputLvl1;
    votingConfigsInput[0] = votingConfigInputLvl2;

    hoax(OWNER);
    governance.setVotingConfigs(votingConfigsInput);
    //-------------------------------------------
    //         asserts
    // ------------------------------------------
    _validateConfigsLvl1(votingConfigInputLvl1, governance);
    _validateConfigsLvl2(votingConfigInputLvl2, governance);
  }

  function _validateConfigsLvl1(
    IGovernanceCore.SetVotingConfigInput memory votingConfigInputLvl1,
    IGovernanceCore governance
  ) internal {
    IGovernanceCore.VotingConfig memory votingConfigL1 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    assertEq(
      votingConfigL1.votingDuration,
      votingConfigInputLvl1.votingDuration
    );
    assertEq(
      votingConfigL1.coolDownBeforeVotingStart,
      votingConfigInputLvl1.coolDownBeforeVotingStart
    );
    assertEq(
      votingConfigL1.yesThreshold,
      votingConfigInputLvl1.yesThreshold / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfigL1.yesNoDifferential,
      votingConfigInputLvl1.yesNoDifferential / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfigL1.minPropositionPower,
      votingConfigInputLvl1.minPropositionPower / governance.PRECISION_DIVIDER()
    );
  }

  function _validateConfigsLvl2(
    IGovernanceCore.SetVotingConfigInput memory votingConfigInputLvl2,
    IGovernanceCore governance
  ) internal {
    IGovernanceCore.VotingConfig memory votingConfigL2 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_2);

    assertEq(
      votingConfigL2.votingDuration,
      votingConfigInputLvl2.votingDuration
    );
    assertEq(
      votingConfigL2.coolDownBeforeVotingStart,
      votingConfigInputLvl2.coolDownBeforeVotingStart
    );
    assertEq(
      votingConfigL2.yesThreshold,
      votingConfigInputLvl2.yesThreshold / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfigL2.yesNoDifferential,
      votingConfigInputLvl2.yesNoDifferential / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfigL2.minPropositionPower,
      votingConfigInputLvl2.minPropositionPower / governance.PRECISION_DIVIDER()
    );
  }

  function _initialize() internal returns (IGovernanceCore) {
    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl1 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: 320_000 ether,
        yesNoDifferential: 100_000 ether,
        minPropositionPower: 50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput
      memory votingConfigInputLvl2 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: votingConfigInputLvl1.yesThreshold + 320_000 ether,
        yesNoDifferential: votingConfigInputLvl1.yesNoDifferential +
          100_000 ether,
        minPropositionPower: votingConfigInputLvl1.minPropositionPower +
          50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](2);
    votingConfigsInput[0] = votingConfigInputLvl1;
    votingConfigsInput[1] = votingConfigInputLvl2;

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    address[] memory powerTokens = new address[](1);
    powerTokens[0] = address(1239746519);

    //-------------------------------------------
    //         call
    // ------------------------------------------
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(IBaseVotingStrategy.getVotingAssetList.selector),
      abi.encode(powerTokens)
    );
    IGovernanceCore governance = IGovernanceCore(
      proxyFactory.createDeterministic(
        address(governanceImpl),
        ProxyAdmin(ADMIN),
        abi.encodeWithSelector(
          IGovernance.initialize.selector,
          OWNER,
          GUARDIAN,
          VOTING_STRATEGY,
          votingConfigsInput,
          votingPortals,
          EXECUTION_GAS_LIMIT
        ),
        GOVERNANCE_CORE_SALT
      )
    );

    return governance;
  }
}
