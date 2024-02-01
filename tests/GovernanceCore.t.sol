// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {ChainIds} from 'aave-delivery-infrastructure/contracts/libs/ChainIds.sol';
import {GovernanceCore} from '../src/contracts/GovernanceCore.sol';
import {Governance, IGovernance, IGovernanceCore, PayloadsControllerUtils, BridgingHelper} from '../src/contracts/Governance.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {IGovernancePowerStrategy} from '../src/interfaces/IGovernancePowerStrategy.sol';
import {IVotingPortal} from '../src/interfaces/IVotingPortal.sol';
import {IVotingMachineWithProofs} from '../src/contracts/voting/interfaces/IVotingMachineWithProofs.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {Errors} from '../src/contracts/libraries/Errors.sol';
import {IBaseVotingStrategy} from '../src/interfaces/IBaseVotingStrategy.sol';

contract GovernanceCoreTest is Test {
  address public constant OWNER = address(123);
  address public constant GUARDIAN = address(1234);
  address public constant ADMIN = address(12345);
  address public constant CROSS_CHAIN_CONTROLLER = address(123456);
  address public constant SAME_CHAIN_VOTING_MACHINE = address(1234567);
  address public constant EXECUTION_PORTAL = address(12345678);
  address public constant VOTING_STRATEGY = address(123456789);
  address public constant VOTING_PORTAL = address(1230123);
  address public constant CANCELLATION_FEE_COLLECTOR = address(123404321);
  uint256 public constant CANCELLATION_FEE = 0.05 ether;
  uint256 public constant EXECUTION_GAS_LIMIT = 400000;
  uint256 public constant COOLDOWN_PERIOD = 1 days;
  uint256 public constant ACHIEVABLE_VOTING_PARTICIPATION = 1_000_000 ether;

  uint256 public CURRENT_CHAIN_ID;
  bytes32 public constant GOVERNANCE_CORE_SALT =
    keccak256('governance core salt');

  IGovernanceCore public governance;
  TransparentProxyFactory public proxyFactory;

  IGovernanceCore.SetVotingConfigInput public votingConfigLvl1 =
    IGovernanceCore.SetVotingConfigInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      votingDuration: uint24(7 days),
      coolDownBeforeVotingStart: uint24(1 days),
      yesThreshold: 320_000 ether,
      yesNoDifferential: 100_000 ether,
      minPropositionPower: 50_000 ether
    });

  IGovernanceCore.SetVotingConfigInput public votingConfigLvl2 =
    IGovernanceCore.SetVotingConfigInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
      votingDuration: uint24(7 days),
      coolDownBeforeVotingStart: uint24(1 days),
      yesThreshold: votingConfigLvl1.yesThreshold + 320_000 ether,
      yesNoDifferential: votingConfigLvl1.yesNoDifferential + 100_000 ether,
      minPropositionPower: votingConfigLvl1.minPropositionPower + 50_000 ether
    });

  event PowerStrategyUpdated(address indexed newPowerStrategy);
  event VotingConfigUpdated(
    PayloadsControllerUtils.AccessControl indexed accessLevel,
    uint24 votingDuration,
    uint24 coolDownBeforeVotingStart,
    uint256 yesThreshold,
    uint256 yesNoDifferential,
    uint256 minPropositionPower
  );
  event VotingPortalUpdated(
    address indexed votingPortal,
    bool indexed approved
  );
  event ProposalCreated(
    uint256 indexed proposalId,
    address indexed creator,
    PayloadsControllerUtils.AccessControl indexed accessLevel,
    bytes32 ipfsHash
  );
  event ProposalQueued(
    uint256 indexed proposalId,
    uint128 votesFor,
    uint128 votesAgainst
  );
  event ProposalFailed(
    uint256 indexed proposalId,
    uint128 votesFor,
    uint128 votesAgainst
  );
  event PayloadSent(
    uint256 indexed proposalId,
    uint40 payloadId,
    address indexed payloadsController,
    uint256 indexed chainId,
    uint256 payloadNumberOnProposal,
    uint256 numberOfPayloadsOnProposal
  );
  event ProposalExecuted(uint256 indexed proposalId);
  event ProposalCanceled(uint256 indexed proposalId);
  event VotingActivated(
    uint256 indexed proposalId,
    bytes32 indexed snapshotBlockHash,
    uint24 votingDuration
  );
  event VoteForwarded(
    uint256 indexed proposalId,
    address indexed voter,
    bool indexed support,
    IVotingMachineWithProofs.VotingAssetWithSlot[] votingAssetWithSlot
  );
  event GasLimitUpdated(uint256 indexed gasLimit);
  event CancellationFeeUpdated(uint256 cancellationFee);
  event CancellationFeeRedeemed(
    uint256 indexed proposalId,
    address indexed to,
    uint256 cancellationFee,
    bool indexed success
  );
  event RepresentativeUpdated(
    address indexed voter,
    address indexed representative,
    uint256 indexed chainId
  );

  function setUp() public {
    CURRENT_CHAIN_ID = ChainIds.ETHEREUM;
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](2);
    votingConfigsInput[0] = votingConfigLvl1;
    votingConfigsInput[1] = votingConfigLvl2;

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    proxyFactory = new TransparentProxyFactory();

    IGovernanceCore governanceImpl = new Governance(
      CROSS_CHAIN_CONTROLLER,
      COOLDOWN_PERIOD,
      CANCELLATION_FEE_COLLECTOR
    );

    address[] memory powerTokens = new address[](1);
    powerTokens[0] = address(1239746519);
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(IBaseVotingStrategy.getVotingAssetList.selector),
      abi.encode(powerTokens)
    );
    governance = IGovernanceCore(
      proxyFactory.createDeterministic(
        address(governanceImpl),
        ADMIN,
        abi.encodeWithSelector(
          IGovernance.initialize.selector,
          OWNER,
          GUARDIAN,
          VOTING_STRATEGY,
          votingConfigsInput,
          votingPortals,
          EXECUTION_GAS_LIMIT,
          CANCELLATION_FEE
        ),
        GOVERNANCE_CORE_SALT
      )
    );
  }

  function testInitializerWhenOnlyLvl1() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigLvl1;

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    IGovernanceCore governanceImpl = new Governance(
      CROSS_CHAIN_CONTROLLER,
      COOLDOWN_PERIOD,
      CANCELLATION_FEE_COLLECTOR
    );

    vm.expectRevert(bytes(Errors.MISSING_VOTING_CONFIGURATIONS));
    proxyFactory.createDeterministic(
      address(governanceImpl),
      ADMIN,
      abi.encodeWithSelector(
        IGovernance.initialize.selector,
        OWNER,
        GUARDIAN,
        VOTING_STRATEGY,
        votingConfigsInput,
        votingPortals,
        EXECUTION_GAS_LIMIT,
        CANCELLATION_FEE
      ),
      GOVERNANCE_CORE_SALT
    );
  }

  function testInitializerWhenBothOfSameLvl() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](2);
    votingConfigsInput[0] = votingConfigLvl1;
    votingConfigsInput[1] = votingConfigLvl1;

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    IGovernanceCore governanceImpl = new Governance(
      CROSS_CHAIN_CONTROLLER,
      COOLDOWN_PERIOD,
      CANCELLATION_FEE_COLLECTOR
    );

    vm.expectRevert(bytes(Errors.INVALID_INITIAL_VOTING_CONFIGS));
    proxyFactory.createDeterministic(
      address(governanceImpl),
      ADMIN,
      abi.encodeWithSelector(
        IGovernance.initialize.selector,
        OWNER,
        GUARDIAN,
        VOTING_STRATEGY,
        votingConfigsInput,
        votingPortals,
        EXECUTION_GAS_LIMIT,
        CANCELLATION_FEE
      ),
      GOVERNANCE_CORE_SALT
    );
  }

  function testInitializerWhenOnlyLvl2() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](1);
    votingConfigsInput[0] = votingConfigLvl2;

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;
    votingConfigsInput[0] = votingConfigLvl1;

    IGovernanceCore governanceImpl = new Governance(
      CROSS_CHAIN_CONTROLLER,
      COOLDOWN_PERIOD,
      CANCELLATION_FEE_COLLECTOR
    );

    vm.expectRevert(bytes(Errors.MISSING_VOTING_CONFIGURATIONS));
    proxyFactory.createDeterministic(
      address(governanceImpl),
      ADMIN,
      abi.encodeWithSelector(
        IGovernance.initialize.selector,
        OWNER,
        GUARDIAN,
        VOTING_STRATEGY,
        votingConfigsInput,
        votingPortals,
        EXECUTION_GAS_LIMIT,
        CANCELLATION_FEE
      ),
      GOVERNANCE_CORE_SALT
    );
  }

  function testInitializerWhenLvlNull() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](2);
    // the first one will have default Level__null
    votingConfigsInput[1] = votingConfigLvl1;

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    IGovernanceCore governanceImpl = new Governance(
      CROSS_CHAIN_CONTROLLER,
      COOLDOWN_PERIOD,
      CANCELLATION_FEE_COLLECTOR
    );

    vm.expectRevert(bytes(Errors.INVALID_VOTING_CONFIG_ACCESS_LEVEL));
    proxyFactory.createDeterministic(
      address(governanceImpl),
      ADMIN,
      abi.encodeWithSelector(
        IGovernance.initialize.selector,
        OWNER,
        GUARDIAN,
        VOTING_STRATEGY,
        votingConfigsInput,
        votingPortals,
        EXECUTION_GAS_LIMIT,
        CANCELLATION_FEE
      ),
      GOVERNANCE_CORE_SALT
    );
  }

  function testInitializerWhenNoConfigs() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](0);

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    IGovernanceCore governanceImpl = new Governance(
      CROSS_CHAIN_CONTROLLER,
      COOLDOWN_PERIOD,
      CANCELLATION_FEE_COLLECTOR
    );

    vm.expectRevert(bytes(Errors.MISSING_VOTING_CONFIGURATIONS));
    proxyFactory.createDeterministic(
      address(governanceImpl),
      ADMIN,
      abi.encodeWithSelector(
        IGovernance.initialize.selector,
        OWNER,
        GUARDIAN,
        VOTING_STRATEGY,
        votingConfigsInput,
        votingPortals,
        EXECUTION_GAS_LIMIT,
        CANCELLATION_FEE
      ),
      GOVERNANCE_CORE_SALT
    );
  }

  function testSetUp() public {
    assertEq(Ownable(address(governance)).owner(), OWNER);
    assertEq(OwnableWithGuardian(address(governance)).guardian(), GUARDIAN);
  }

  function testUpdateGasLimit() public {
    uint256 newGasLimit = 900_000;
    hoax(OWNER);
    vm.expectEmit(true, false, false, true);
    emit GasLimitUpdated(newGasLimit);
    IGovernance(address(governance)).updateGasLimit(newGasLimit);

    assertEq(IGovernance(address(governance)).getGasLimit(), newGasLimit);
  }

  function testUpdateGasLimitWhenNotOwner() public {
    uint256 newGasLimit = 500000;
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    IGovernance(address(governance)).updateGasLimit(newGasLimit);
  }

  function testCreateGovernanceWhenInvalidCCC() public {
    vm.expectRevert(bytes(Errors.INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS));
    new Governance(address(0), COOLDOWN_PERIOD, CANCELLATION_FEE_COLLECTOR);
  }

  function testCreateGovernanceWhenInvalidCollector() public {
    vm.expectRevert(bytes(Errors.INVALID_CANCELLATION_FEE_COLLECTOR));
    new Governance(CROSS_CHAIN_CONTROLLER, COOLDOWN_PERIOD, address(0));
  }

  // TEST GETTERS
  function testGetPrecisionDivider() public {
    assertEq(governance.PRECISION_DIVIDER(), 1 ether);
  }

  function testIsVotingPortalApproved() public {
    assertEq(governance.isVotingPortalApproved(VOTING_PORTAL), true);
  }

  function testGetVotingPortalCount() public {
    assertEq(governance.getVotingPortalsCount(), 1);
  }

  function testGetCooldownPeriod() public {
    assertEq(governance.COOLDOWN_PERIOD(), 1 days);
  }

  function testGetProposalExpirationTime() public {
    assertEq(governance.PROPOSAL_EXPIRATION_TIME(), 30 days);
  }

  function testGetProposalsCount() public {
    assertEq(governance.getProposalsCount(), 0);
  }

  function testGetPowerStrategy() public {
    assertEq(address(governance.getPowerStrategy()), VOTING_STRATEGY);
  }

  function testGetVotingConfigs() public {
    IGovernanceCore.VotingConfig memory votingConfig = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    assertEq(votingConfig.votingDuration, votingConfigLvl1.votingDuration);
    assertEq(
      votingConfig.coolDownBeforeVotingStart,
      votingConfigLvl1.coolDownBeforeVotingStart
    );
    assertEq(
      votingConfig.yesThreshold,
      votingConfigLvl1.yesThreshold / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfig.yesNoDifferential,
      votingConfigLvl1.yesNoDifferential / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfig.minPropositionPower,
      votingConfigLvl1.minPropositionPower / governance.PRECISION_DIVIDER()
    );
  }

  // TEST SETTERS
  function testSetPowerStrategy() public {
    address newPowerStrategy = address(101);

    hoax(OWNER);
    address[] memory powerTokens = new address[](1);
    powerTokens[0] = address(1239746519);
    vm.mockCall(
      newPowerStrategy,
      abi.encodeWithSelector(IBaseVotingStrategy.getVotingAssetList.selector),
      abi.encode(powerTokens)
    );
    vm.expectEmit(true, false, false, true);
    emit PowerStrategyUpdated(newPowerStrategy);
    governance.setPowerStrategy(IGovernancePowerStrategy(newPowerStrategy));

    assertEq(address(governance.getPowerStrategy()), newPowerStrategy);
  }

  function testSetPowerStrategyWithNoPowerTokens() public {
    address newPowerStrategy = address(101);

    hoax(OWNER);
    vm.mockCall(
      newPowerStrategy,
      abi.encodeWithSelector(IBaseVotingStrategy.getVotingAssetList.selector),
      abi.encode(new address[](0))
    );
    vm.expectRevert(bytes(Errors.POWER_STRATEGY_HAS_NO_TOKENS));
    governance.setPowerStrategy(IGovernancePowerStrategy(newPowerStrategy));
  }

  function testSetZeroPowerStrategy() public {
    address newPowerStrategy = address(0);

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_POWER_STRATEGY));
    governance.setPowerStrategy(IGovernancePowerStrategy(newPowerStrategy));
  }

  function testSetPowerStrategyWhenNotOwner() public {
    address newPowerStrategy = address(101);

    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    governance.setPowerStrategy(IGovernancePowerStrategy(newPowerStrategy));
    assertEq(address(governance.getPowerStrategy()), VOTING_STRATEGY);
  }

  function testSetVotingConfigs() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](2);

    IGovernanceCore.SetVotingConfigInput
      memory newVotingConfigLvl1 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: 320_000 ether,
        yesNoDifferential: 100_000 ether,
        minPropositionPower: 50_000 ether
      });

    IGovernanceCore.SetVotingConfigInput
      memory newVotingConfigLvl2 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        votingDuration: uint24(7 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: newVotingConfigLvl1.yesThreshold + 320_000 ether,
        yesNoDifferential: newVotingConfigLvl1.yesNoDifferential +
          100_000 ether,
        minPropositionPower: newVotingConfigLvl1.minPropositionPower +
          50_000 ether
      });

    newVotingConfigs[0] = newVotingConfigLvl1;
    newVotingConfigs[1] = newVotingConfigLvl2;

    vm.expectEmit(true, true, false, true);
    emit VotingConfigUpdated(
      newVotingConfigLvl1.accessLevel,
      newVotingConfigLvl1.votingDuration,
      newVotingConfigLvl1.coolDownBeforeVotingStart,
      newVotingConfigLvl1.yesThreshold / governance.PRECISION_DIVIDER(),
      newVotingConfigLvl1.yesNoDifferential / governance.PRECISION_DIVIDER(),
      newVotingConfigLvl1.minPropositionPower / governance.PRECISION_DIVIDER()
    );
    vm.expectEmit(true, true, false, true);
    emit VotingConfigUpdated(
      newVotingConfigLvl2.accessLevel,
      newVotingConfigLvl2.votingDuration,
      newVotingConfigLvl2.coolDownBeforeVotingStart,
      newVotingConfigLvl2.yesThreshold / governance.PRECISION_DIVIDER(),
      newVotingConfigLvl2.yesNoDifferential / governance.PRECISION_DIVIDER(),
      newVotingConfigLvl2.minPropositionPower / governance.PRECISION_DIVIDER()
    );
    hoax(OWNER);
    governance.setVotingConfigs(newVotingConfigs);

    IGovernanceCore.VotingConfig memory votingConfigL1 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_1);

    assertEq(votingConfigL1.votingDuration, newVotingConfigLvl1.votingDuration);
    assertEq(
      votingConfigL1.coolDownBeforeVotingStart,
      newVotingConfigLvl1.coolDownBeforeVotingStart
    );
    assertEq(
      votingConfigL1.yesThreshold,
      newVotingConfigLvl1.yesThreshold / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfigL1.yesNoDifferential,
      newVotingConfigLvl1.yesNoDifferential / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfigL1.minPropositionPower,
      newVotingConfigLvl1.minPropositionPower / governance.PRECISION_DIVIDER()
    );

    IGovernanceCore.VotingConfig memory votingConfigL2 = governance
      .getVotingConfig(PayloadsControllerUtils.AccessControl.Level_2);

    assertEq(votingConfigL2.votingDuration, newVotingConfigLvl2.votingDuration);
    assertEq(
      votingConfigL2.coolDownBeforeVotingStart,
      newVotingConfigLvl2.coolDownBeforeVotingStart
    );
    assertEq(
      votingConfigL2.yesThreshold,
      newVotingConfigLvl2.yesThreshold / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfigL2.yesNoDifferential,
      newVotingConfigLvl2.yesNoDifferential / governance.PRECISION_DIVIDER()
    );
    assertEq(
      votingConfigL2.minPropositionPower,
      newVotingConfigLvl2.minPropositionPower / governance.PRECISION_DIVIDER()
    );
  }

  function testSetVotingConfigsWhenInvalidAccessLevel() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);

    IGovernanceCore.SetVotingConfigInput
      memory newVotingConfigLvl1 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_null,
        votingDuration: uint24(3 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: 120000 ether,
        yesNoDifferential: 150000 ether,
        minPropositionPower: 20000 ether
      });

    newVotingConfigs[0] = newVotingConfigLvl1;

    vm.expectRevert(bytes(Errors.INVALID_VOTING_CONFIG_ACCESS_LEVEL));
    hoax(OWNER);
    governance.setVotingConfigs(newVotingConfigs);
  }

  function testSetVotingConfigsWhenDurationToBig() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);

    IGovernanceCore.SetVotingConfigInput
      memory newVotingConfigLvl1 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        votingDuration: uint24(governance.PROPOSAL_EXPIRATION_TIME()),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: 120000 ether,
        yesNoDifferential: 150000 ether,
        minPropositionPower: 20000 ether
      });

    newVotingConfigs[0] = newVotingConfigLvl1;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_VOTING_DURATION));
    governance.setVotingConfigs(newVotingConfigs);
  }

  function testSetVotingConfigsWhenDurationToSmall() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);

    IGovernanceCore.SetVotingConfigInput
      memory newVotingConfigLvl1 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        votingDuration: uint24(2),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: 120000 ether,
        yesNoDifferential: 150000 ether,
        minPropositionPower: 20000 ether
      });

    newVotingConfigs[0] = newVotingConfigLvl1;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.VOTING_DURATION_TOO_SMALL));
    governance.setVotingConfigs(newVotingConfigs);
  }

  function testSetVotingConfigsWhenNotOwner() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);

    IGovernanceCore.SetVotingConfigInput
      memory newVotingConfigLvl1 = IGovernanceCore.SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
        votingDuration: uint24(3 days),
        coolDownBeforeVotingStart: uint24(1 days),
        yesThreshold: 120000 ether,
        yesNoDifferential: 150000 ether,
        minPropositionPower: 20000 ether
      });

    newVotingConfigs[0] = newVotingConfigLvl1;

    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    governance.setVotingConfigs(newVotingConfigs);
  }

  function testAddVotingPortals() public {
    address newVotingPortal = address(101);

    address[] memory newVotingPortals = new address[](1);
    newVotingPortals[0] = newVotingPortal;

    vm.expectEmit(true, true, false, true);
    emit VotingPortalUpdated(newVotingPortal, true);
    hoax(OWNER);
    governance.addVotingPortals(newVotingPortals);

    assertEq(governance.isVotingPortalApproved(newVotingPortal), true);
    assertEq(governance.getVotingPortalsCount(), 2);
  }

  function testAddAndRemoveSameVotingPortalTwice() public {
    address newVotingPortal = address(101);

    address[] memory newVotingPortals = new address[](1);
    newVotingPortals[0] = newVotingPortal;

    hoax(OWNER);
    governance.addVotingPortals(newVotingPortals);
    hoax(OWNER);
    governance.addVotingPortals(newVotingPortals);

    assertEq(governance.isVotingPortalApproved(newVotingPortal), true);
    assertEq(governance.getVotingPortalsCount(), 2);

    hoax(OWNER);
    governance.removeVotingPortals(newVotingPortals);
    hoax(OWNER);
    governance.removeVotingPortals(newVotingPortals);

    assertEq(governance.isVotingPortalApproved(newVotingPortal), false);
    assertEq(governance.getVotingPortalsCount(), 1);
  }

  function testAddAddressZeroAsVotingPortal() public {
    address newVotingPortal = address(0);

    address[] memory newVotingPortals = new address[](1);
    newVotingPortals[0] = newVotingPortal;

    hoax(OWNER);
    vm.expectRevert(bytes(Errors.INVALID_VOTING_PORTAL_ADDRESS));
    governance.addVotingPortals(newVotingPortals);
  }

  function testAddVotingPortalsWhenNotOwner() public {
    address newVotingPortal = address(101);

    address[] memory newVotingPortals = new address[](1);
    newVotingPortals[0] = newVotingPortal;

    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    governance.addVotingPortals(newVotingPortals);
    assertEq(governance.getVotingPortalsCount(), 1);
  }

  function testRemoveVotingPortals() public {
    address[] memory newVotingPortals = new address[](1);
    newVotingPortals[0] = VOTING_PORTAL;

    vm.expectEmit(true, true, false, true);
    emit VotingPortalUpdated(VOTING_PORTAL, false);
    hoax(OWNER);
    governance.removeVotingPortals(newVotingPortals);

    assertEq(governance.isVotingPortalApproved(VOTING_PORTAL), false);
    assertEq(governance.getVotingPortalsCount(), 0);
  }

  function testRemoveVotingPortalsWhenNotOwner() public {
    address[] memory newVotingPortals = new address[](1);
    newVotingPortals[0] = VOTING_PORTAL;

    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    governance.removeVotingPortals(newVotingPortals);
    assertEq(governance.getVotingPortalsCount(), 1);
  }

  function testRescueVotingPortal() public {
    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    hoax(OWNER);
    governance.removeVotingPortals(votingPortals);

    address rescueVotingPortal = address(90123478);

    vm.expectEmit(true, true, false, true);
    emit VotingPortalUpdated(rescueVotingPortal, true);
    hoax(GUARDIAN);
    governance.rescueVotingPortal(rescueVotingPortal);

    assertEq(governance.isVotingPortalApproved(rescueVotingPortal), true);
    assertEq(governance.getVotingPortalsCount(), 1);
  }

  function testRescueVotingPortalWhenVotingPortalsCountNot0() public {
    address rescueVotingPortal = address(90123478);

    vm.expectRevert(bytes(Errors.VOTING_PORTALS_COUNT_NOT_0));
    hoax(GUARDIAN);
    governance.rescueVotingPortal(rescueVotingPortal);

    assertEq(governance.isVotingPortalApproved(rescueVotingPortal), false);
    assertEq(governance.getVotingPortalsCount(), 1);
  }

  function estRescueVotingPortalWhenNotGuardian() public {
    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;

    hoax(OWNER);
    governance.removeVotingPortals(votingPortals);

    address rescueVotingPortal = address(90123478);
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    governance.rescueVotingPortal(rescueVotingPortal);

    assertEq(governance.getVotingPortalsCount(), 0);
  }

  // TEST CREATE PROPOSAL
  function testCreateProposal() public {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_1;
    PayloadsControllerUtils.AccessControl accessLevel2 = PayloadsControllerUtils
      .AccessControl
      .Level_2;
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](2);
    PayloadsControllerUtils.Payload memory payload = _createPayload(
      accessLevel
    );
    PayloadsControllerUtils.Payload memory payloadLvl2 = _createPayload(
      accessLevel2
    );
    payloads[0] = payloadLvl2;
    payloads[1] = payload;

    // set voting config lvl2
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);
    newVotingConfigs[0] = votingConfigLvl2;

    hoax(OWNER, 1 ether);
    governance.setVotingConfigs(newVotingConfigs);

    bytes32 ipfsHash = keccak256(bytes('some ipfs hash'));
    bytes32 blockHash = blockhash(block.number - 1);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    vm.mockCall(
      VOTING_PORTAL,
      abi.encodeWithSelector(
        IVotingPortal.forwardStartVotingMessage.selector,
        0,
        blockHash,
        votingConfigLvl1.votingDuration
      ),
      abi.encode()
    );

    uint256 balanceBefore = address(this).balance;

    vm.expectEmit(true, true, true, true);
    emit ProposalCreated(0, address(this), accessLevel2, ipfsHash);
    uint256 proposalId = governance.createProposal{value: CANCELLATION_FEE}(
      payloads,
      VOTING_PORTAL,
      ipfsHash
    );

    vm.clearMockedCalls();

    IGovernanceCore.Proposal memory proposal = governance.getProposal(0);

    assertEq(governance.getProposalsCount(), 1);

    assertEq(proposal.votingDuration, uint24(0));
    assertEq(proposal.creationTime, uint40(block.timestamp));
    assertEq(uint8(proposal.accessLevel), uint8(accessLevel2));
    assertEq(uint8(proposal.state), uint8(1));
    assertEq(proposal.creator, address(this));

    assertEq(proposal.payloads.length, 2);
    assertEq(proposal.payloads[0].chain, ChainIds.POLYGON);
    assertEq(uint8(proposal.payloads[0].accessLevel), uint8(accessLevel2));
    assertEq(proposal.payloads[0].payloadsController, address(123012491456));
    assertEq(proposal.payloads[0].payloadId, uint40(0));

    assertEq(proposal.payloads[1].chain, ChainIds.POLYGON);
    assertEq(uint8(proposal.payloads[1].accessLevel), uint8(accessLevel));
    assertEq(proposal.payloads[1].payloadsController, address(123012491456));
    assertEq(proposal.payloads[1].payloadId, uint40(0));

    assertEq(proposal.queuingTime, uint40(0));
    assertEq(proposal.votingPortal, VOTING_PORTAL);
    assertEq(proposal.ipfsHash, ipfsHash);
    assertEq(proposal.forVotes, 0);
    assertEq(proposal.againstVotes, 0);

    IGovernanceCore.Proposal memory proposalAfter = governance.getProposal(
      proposalId
    );
    assertEq(proposalAfter.cancellationFee, CANCELLATION_FEE);
    assertEq(address(this).balance, balanceBefore - CANCELLATION_FEE);
    assertEq(address(governance).balance, CANCELLATION_FEE);
  }

  function testCreateProposalWhenNotCorrectCancellationFee() public {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_1;
    PayloadsControllerUtils.AccessControl accessLevel2 = PayloadsControllerUtils
      .AccessControl
      .Level_2;
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](2);
    PayloadsControllerUtils.Payload memory payload = _createPayload(
      accessLevel
    );
    PayloadsControllerUtils.Payload memory payloadLvl2 = _createPayload(
      accessLevel2
    );
    payloads[0] = payloadLvl2;
    payloads[1] = payload;

    // set voting config lvl2
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);
    newVotingConfigs[0] = votingConfigLvl2;

    hoax(OWNER);
    uint256 balanceBefore = OWNER.balance;
    governance.setVotingConfigs(newVotingConfigs);

    bytes32 ipfsHash = keccak256(bytes('some ipfs hash'));
    bytes32 blockHash = blockhash(block.number - 1);

    vm.expectRevert(bytes(Errors.INVALID_CANCELLATION_FEE_SENT));
    emit ProposalCreated(0, address(this), accessLevel2, ipfsHash);
    governance.createProposal{value: 0.002 ether}(
      payloads,
      VOTING_PORTAL,
      ipfsHash
    );

    vm.clearMockedCalls();
  }

  function testCreateProposalWhenInvalidIPFSHash() public {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_1;
    PayloadsControllerUtils.AccessControl accessLevel2 = PayloadsControllerUtils
      .AccessControl
      .Level_2;
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](2);
    PayloadsControllerUtils.Payload memory payload = _createPayload(
      accessLevel
    );
    PayloadsControllerUtils.Payload memory payloadLvl2 = _createPayload(
      accessLevel2
    );
    payloads[0] = payloadLvl2;
    payloads[1] = payload;

    // set voting config lvl2
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);
    newVotingConfigs[0] = votingConfigLvl2;

    hoax(OWNER, 1 ether);
    governance.setVotingConfigs(newVotingConfigs);

    vm.expectRevert(bytes(Errors.G_INVALID_IPFS_HASH));
    governance.createProposal{value: CANCELLATION_FEE}(
      payloads,
      VOTING_PORTAL,
      bytes32(0)
    );
    vm.clearMockedCalls();
  }

  function testCreateProposalWhenInvalidAccessLevel() public {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_null;
    PayloadsControllerUtils.AccessControl accessLevel2 = PayloadsControllerUtils
      .AccessControl
      .Level_2;
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](2);
    PayloadsControllerUtils.Payload memory payload = _createPayload(
      accessLevel
    );
    PayloadsControllerUtils.Payload memory payloadLvl2 = _createPayload(
      accessLevel2
    );
    payloads[0] = payloadLvl2;
    payloads[1] = payload;

    // set voting config lvl2
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);
    newVotingConfigs[0] = votingConfigLvl2;

    hoax(OWNER);
    governance.setVotingConfigs(newVotingConfigs);

    bytes32 ipfsHash = keccak256(bytes('some ipfs hash'));

    vm.expectRevert(bytes(Errors.G_INVALID_PAYLOAD_ACCESS_LEVEL));
    governance.createProposal{value: CANCELLATION_FEE}(
      payloads,
      VOTING_PORTAL,
      ipfsHash
    );
    vm.clearMockedCalls();
  }

  function testCreateProposalWhenInvalidPayloadsController() public {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_1;
    PayloadsControllerUtils.AccessControl accessLevel2 = PayloadsControllerUtils
      .AccessControl
      .Level_2;
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](2);
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        chain: ChainIds.POLYGON,
        accessLevel: accessLevel,
        payloadsController: address(0),
        payloadId: uint40(0)
      });
    PayloadsControllerUtils.Payload memory payloadLvl2 = _createPayload(
      accessLevel2
    );
    payloads[0] = payloadLvl2;
    payloads[1] = payload;

    // set voting config lvl2
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);
    newVotingConfigs[0] = votingConfigLvl2;

    hoax(OWNER);
    governance.setVotingConfigs(newVotingConfigs);

    bytes32 ipfsHash = keccak256(bytes('some ipfs hash'));

    vm.expectRevert(bytes(Errors.G_INVALID_PAYLOADS_CONTROLLER));
    governance.createProposal{value: CANCELLATION_FEE}(
      payloads,
      VOTING_PORTAL,
      ipfsHash
    );
    vm.clearMockedCalls();
  }

  function testCreateProposalWhenInvalidChain() public {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_1;
    PayloadsControllerUtils.AccessControl accessLevel2 = PayloadsControllerUtils
      .AccessControl
      .Level_2;
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](2);
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        chain: 0,
        accessLevel: accessLevel,
        payloadsController: address(123012491456),
        payloadId: uint40(0)
      });
    PayloadsControllerUtils.Payload memory payloadLvl2 = _createPayload(
      accessLevel2
    );
    payloads[0] = payloadLvl2;
    payloads[1] = payload;

    // set voting config lvl2
    IGovernanceCore.SetVotingConfigInput[]
      memory newVotingConfigs = new IGovernanceCore.SetVotingConfigInput[](1);
    newVotingConfigs[0] = votingConfigLvl2;

    hoax(OWNER);
    governance.setVotingConfigs(newVotingConfigs);

    bytes32 ipfsHash = keccak256(bytes('some ipfs hash'));

    vm.expectRevert(bytes(Errors.G_INVALID_PAYLOAD_CHAIN));
    governance.createProposal{value: CANCELLATION_FEE}(
      payloads,
      VOTING_PORTAL,
      ipfsHash
    );
    vm.clearMockedCalls();
  }

  function testCreateProposalWhenNoPayloads() public {
    vm.expectRevert(bytes(Errors.AT_LEAST_ONE_PAYLOAD));
    governance.createProposal{value: CANCELLATION_FEE}(
      new PayloadsControllerUtils.Payload[](0),
      VOTING_PORTAL,
      keccak256(bytes('some hash'))
    );
  }

  function testCreateProposalWhenVotingPortalNotApproved() public {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_1;
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](1);
    PayloadsControllerUtils.Payload memory payload = _createPayload(
      accessLevel
    );
    payloads[0] = payload;

    vm.expectRevert(bytes(Errors.VOTING_PORTAL_NOT_APPROVED));
    governance.createProposal{value: CANCELLATION_FEE}(
      payloads,
      address(123076),
      keccak256(bytes('some hash'))
    );
  }

  function testCreateProposalWhenPropositionPowerTooLow() public {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_1;
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](1);
    PayloadsControllerUtils.Payload memory payload = _createPayload(
      accessLevel
    );
    payloads[0] = payload;

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10 ether)
    );
    vm.expectRevert(bytes(Errors.PROPOSITION_POWER_IS_TOO_LOW));
    governance.createProposal{value: CANCELLATION_FEE}(
      payloads,
      VOTING_PORTAL,
      keccak256(bytes('some hash'))
    );
    vm.clearMockedCalls();
  }

  // ACTIVATE VOTING
  function testActivateVoting() public {
    uint256 proposalId = _createProposal();
    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );
    IGovernanceCore.VotingConfig memory config = governance.getVotingConfig(
      proposal.payloads[0].accessLevel
    );

    skip(config.coolDownBeforeVotingStart + 1);
    vm.mockCall(
      VOTING_PORTAL,
      abi.encodeWithSelector(IVotingPortal.forwardStartVotingMessage.selector),
      abi.encode()
    );
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(1000000 ether)
    );
    vm.expectEmit(true, true, false, true);
    emit VotingActivated(
      proposalId,
      blockhash(block.number - 1),
      config.votingDuration
    );
    governance.activateVoting(proposalId);

    IGovernanceCore.Proposal memory proposalAfter = governance.getProposal(
      proposalId
    );
    assertEq(proposalAfter.votingActivationTime, uint40(block.timestamp));
    assertEq(proposalAfter.snapshotBlockHash, blockhash(block.number - 1));
  }

  function testActivateVotingWhenVotingPortalNotApproved() public {
    uint256 proposalId = _createProposal();
    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );
    IGovernanceCore.VotingConfig memory config = governance.getVotingConfig(
      proposal.payloads[0].accessLevel
    );

    skip(config.coolDownBeforeVotingStart + 1);

    address[] memory votingPortalsToRemove = new address[](1);
    votingPortalsToRemove[0] = VOTING_PORTAL;

    hoax(OWNER);
    governance.removeVotingPortals(votingPortalsToRemove);

    vm.expectRevert(bytes(Errors.VOTING_PORTAL_NOT_APPROVED));
    governance.activateVoting(proposalId);
  }

  function testActivateVotingWhenNoPower() public {
    uint256 proposalId = _createProposal();
    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );
    IGovernanceCore.VotingConfig memory config = governance.getVotingConfig(
      proposal.payloads[0].accessLevel
    );

    skip(config.coolDownBeforeVotingStart + 1);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(0)
    );
    vm.expectRevert(bytes(Errors.PROPOSITION_POWER_IS_TOO_LOW));
    governance.activateVoting(proposalId);
  }

  function testActivateVotingWhenIncorrectState() public {
    vm.expectRevert(bytes(Errors.PROPOSAL_NOT_IN_CREATED_STATE));
    governance.activateVoting(2);
  }

  function testActivateVotingWhenCoolDownNotPassed() public {
    uint256 proposalId = _createProposal();
    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );
    IGovernanceCore.VotingConfig memory config = governance.getVotingConfig(
      proposal.payloads[0].accessLevel
    );

    skip(config.coolDownBeforeVotingStart - 10);

    vm.expectRevert(bytes(Errors.VOTING_START_COOLDOWN_PERIOD_NOT_PASSED));
    governance.activateVoting(proposalId);
  }

  // QUEUE PROPOSAL
  function testQueueProposal() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    uint128 forVotes = 1000000 ether;
    uint128 againstVotes = 1 ether;

    IGovernanceCore.Proposal memory preProposal = governance.getProposal(
      proposalId
    );
    skip(
      block.timestamp +
        preProposal.votingDuration +
        preProposal.votingActivationTime +
        1
    );

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    vm.expectEmit(true, false, false, true);
    emit ProposalQueued(proposalId, forVotes, againstVotes);
    hoax(VOTING_PORTAL);
    governance.queueProposal(proposalId, forVotes, againstVotes);
    vm.clearMockedCalls();

    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );

    assertEq(uint8(proposal.state), uint8(3));
    assertEq(proposal.queuingTime, uint40(block.timestamp));
    assertEq(proposal.forVotes, forVotes);
    assertEq(proposal.againstVotes, againstVotes);
  }

  function testQueueProposalWhenVotingDurationNotPassed() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    uint128 forVotes = 1000000 ether;
    uint128 againstVotes = 1 ether;

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    vm.expectRevert(bytes(Errors.VOTING_DURATION_NOT_PASSED));
    hoax(VOTING_PORTAL);
    governance.queueProposal(proposalId, forVotes, againstVotes);
    vm.clearMockedCalls();
  }

  function testQueueProposalWhenCallerNotVotingPortal() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);

    IGovernanceCore.Proposal memory preProposal = governance.getProposal(
      proposalId
    );
    skip(
      block.timestamp +
        preProposal.votingDuration +
        preProposal.votingActivationTime +
        1
    );

    uint128 forVotes = 1000000 ether;
    uint128 againstVotes = 1 ether;
    vm.expectRevert(bytes(Errors.CALLER_NOT_A_VALID_VOTING_PORTAL));
    governance.queueProposal(proposalId, forVotes, againstVotes);
  }

  function testQueueProposalWhenNotInCreatedState() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    uint128 forVotes = 1000000 ether;
    uint128 againstVotes = 1 ether;

    IGovernanceCore.Proposal memory preProposal = governance.getProposal(
      proposalId
    );
    skip(
      block.timestamp +
        preProposal.votingDuration +
        preProposal.votingActivationTime +
        1
    );

    _queueProposal(proposalId);

    hoax(VOTING_PORTAL);
    vm.expectRevert(bytes(Errors.PROPOSAL_NOT_IN_ACTIVE_STATE));
    governance.queueProposal(proposalId, forVotes, againstVotes);
  }

  function testQueueProposalWhenNotPropositionPower() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    uint128 forVotes = 1000000 ether;
    uint128 againstVotes = 1 ether;

    IGovernanceCore.Proposal memory preProposal = governance.getProposal(
      proposalId
    );
    skip(
      block.timestamp +
        preProposal.votingDuration +
        preProposal.votingActivationTime +
        1
    );

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(0 ether)
    );
    vm.expectEmit(true, false, false, true);
    emit ProposalFailed(proposalId, forVotes, againstVotes);
    hoax(VOTING_PORTAL);
    governance.queueProposal(proposalId, forVotes, againstVotes);
    vm.clearMockedCalls();

    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );

    assertEq(uint8(proposal.state), uint8(5));
    assertEq(proposal.queuingTime, uint40(0));
    assertEq(proposal.forVotes, forVotes);
    assertEq(proposal.againstVotes, againstVotes);
  }

  function testQueueProposalWhenNotPassingYesThreshold() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    uint128 forVotes = 100 ether;
    uint128 againstVotes = 1 ether;

    IGovernanceCore.Proposal memory preProposal = governance.getProposal(
      proposalId
    );
    skip(
      block.timestamp +
        preProposal.votingDuration +
        preProposal.votingActivationTime +
        1
    );

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    vm.expectEmit(true, false, false, true);
    emit ProposalFailed(proposalId, forVotes, againstVotes);
    hoax(VOTING_PORTAL);
    governance.queueProposal(proposalId, forVotes, againstVotes);
    vm.clearMockedCalls();

    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );

    assertEq(uint8(proposal.state), uint8(5));
    assertEq(proposal.queuingTime, uint40(0));
    assertEq(proposal.forVotes, forVotes);
    assertEq(proposal.againstVotes, againstVotes);
  }

  function testQueueProposalWhenNotPassingYesNoDifferential() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    uint128 forVotes = 1000000 ether;
    uint128 againstVotes = 1000000 ether;

    IGovernanceCore.Proposal memory preProposal = governance.getProposal(
      proposalId
    );
    skip(
      block.timestamp +
        preProposal.votingDuration +
        preProposal.votingActivationTime +
        1
    );

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(0 ether)
    );
    vm.expectEmit(true, false, false, true);
    emit ProposalFailed(proposalId, forVotes, againstVotes);
    hoax(VOTING_PORTAL);
    governance.queueProposal(proposalId, forVotes, againstVotes);
    vm.clearMockedCalls();

    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );

    assertEq(uint8(proposal.state), uint8(5));
    assertEq(proposal.queuingTime, uint40(0));
    assertEq(proposal.forVotes, forVotes);
    assertEq(proposal.againstVotes, againstVotes);
  }

  // EXECUTE PROPOSAL
  function testExecuteProposal() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    _queueProposal(proposalId);

    IGovernanceCore.Proposal memory preProposal = governance.getProposal(
      proposalId
    );

    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        chain: preProposal.payloads[0].chain,
        accessLevel: preProposal.payloads[0].accessLevel,
        payloadsController: preProposal.payloads[0].payloadsController,
        payloadId: preProposal.payloads[0].payloadId
      });

    bytes memory messageWithType = BridgingHelper.encodePayloadExecutionMessage(
      payload,
      preProposal.votingActivationTime
    );

    skip(
      block.timestamp +
        preProposal.queuingTime +
        governance.COOLDOWN_PERIOD() +
        10
    );
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    vm.mockCall(
      CROSS_CHAIN_CONTROLLER,
      abi.encodeWithSelector(
        ICrossChainForwarder.forwardMessage.selector,
        preProposal.payloads[0].chain,
        preProposal.payloads[0].payloadsController,
        EXECUTION_GAS_LIMIT,
        messageWithType
      ),
      abi.encode(bytes32(0), bytes32(0))
    );

    vm.expectEmit(true, true, true, true);
    emit PayloadSent(
      proposalId,
      preProposal.payloads[0].payloadId,
      preProposal.payloads[0].payloadsController,
      preProposal.payloads[0].chain,
      0,
      preProposal.payloads.length
    );
    vm.expectEmit(true, false, false, true);
    emit ProposalExecuted(proposalId);
    governance.executeProposal(proposalId);
    vm.clearMockedCalls();

    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );

    assertEq(uint8(proposal.state), uint8(4));
  }

  function testExecuteProposalWhenNoPower() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    _queueProposal(proposalId);

    IGovernanceCore.Proposal memory preProposal = governance.getProposal(
      proposalId
    );

    skip(
      block.timestamp +
        preProposal.queuingTime +
        governance.COOLDOWN_PERIOD() +
        1
    );
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(0 ether)
    );
    vm.expectRevert(bytes(Errors.PROPOSITION_POWER_IS_TOO_LOW));
    governance.executeProposal(proposalId);
    vm.clearMockedCalls();
  }

  function testExecuteProposalWhenNotInQueuedState() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);

    vm.expectRevert(bytes(Errors.PROPOSAL_NOT_IN_QUEUED_STATE));
    governance.executeProposal(proposalId);
  }

  function testExecuteProposalWhenInCoolDownPeriod() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    _queueProposal(proposalId);

    vm.expectRevert(bytes(Errors.QUEUE_COOLDOWN_PERIOD_NOT_PASSED));
    governance.executeProposal(proposalId);
  }

  // TEST CANCEL PROPOSAL
  function testCancelProposalWhenNotPower() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(0 ether)
    );
    vm.expectEmit(true, false, false, true);
    emit ProposalCanceled(proposalId);
    hoax(address(1234081598));
    governance.cancelProposal(proposalId);
    vm.clearMockedCalls();
  }

  function testCancelProposalWhenVotingPortalNotApproved() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);

    address[] memory votingPortalsToRemove = new address[](1);
    votingPortalsToRemove[0] = VOTING_PORTAL;

    hoax(OWNER);
    governance.removeVotingPortals(votingPortalsToRemove);

    hoax(address(123013249));
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(100000000 ether)
    );
    vm.expectEmit(true, false, false, true);
    emit ProposalCanceled(proposalId);
    governance.cancelProposal(proposalId);
    vm.clearMockedCalls();
  }

  function testCancelProposalWhenCreator() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(100000000 ether)
    );
    vm.expectEmit(true, false, false, true);
    emit ProposalCanceled(proposalId);
    governance.cancelProposal(proposalId);
    vm.clearMockedCalls();
  }

  function testCancelProposalWhenGuardian() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(100000000 ether)
    );
    vm.expectEmit(true, false, false, true);
    emit ProposalCanceled(proposalId);
    hoax(GUARDIAN);
    governance.cancelProposal(proposalId);
    vm.clearMockedCalls();
  }

  function testCancelProposalWhenNotGuardianOrCreatorAndPower() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(100000000 ether)
    );
    vm.expectRevert(bytes('ONLY_BY_GUARDIAN'));
    hoax(address(1230163278));
    governance.cancelProposal(proposalId);
    vm.clearMockedCalls();
  }

  function testCancelProposalWhenExecuted() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    _queueProposal(proposalId);

    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );

    _executeProposal(proposalId);

    vm.expectRevert(bytes(Errors.PROPOSAL_NOT_IN_THE_CORRECT_STATE));
    governance.cancelProposal(proposalId);
  }

  // TEST REDEEM CANCELLATION FEE
  function testRedeemWhenProposalInInvalidState() public {
    uint256 balanceBefore = address(this).balance;
    uint256 proposalId = _createProposal();

    assertEq(address(governance).balance, CANCELLATION_FEE);
    uint256 balanceAfter = address(this).balance;

    _activateVote(proposalId);
    _queueProposal(proposalId);

    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;

    vm.expectRevert(bytes(Errors.INVALID_STATE_TO_REDEEM_CANCELLATION_FEE));
    governance.redeemCancellationFee(proposalIds);

    uint256 balanceNow = address(this).balance;
    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );
    assertEq(proposal.cancellationFee, CANCELLATION_FEE);
    assertEq(balanceBefore, balanceAfter + CANCELLATION_FEE);
    assertEq(balanceNow, balanceBefore - CANCELLATION_FEE);
  }

  function testRedeemWhenProposalAlreadyRedeemed() public {
    uint256 balanceBefore = address(this).balance;
    uint256 proposalId = _createProposal();

    assertEq(address(governance).balance, CANCELLATION_FEE);
    uint256 balanceAfter = address(this).balance;

    _activateVote(proposalId);
    _queueProposal(proposalId);
    _executeProposal(proposalId);

    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;

    governance.redeemCancellationFee(proposalIds);

    vm.expectRevert(bytes(Errors.CANCELLATION_FEE_ALREADY_REDEEMED));
    governance.redeemCancellationFee(proposalIds);

    uint256 balanceNow = address(this).balance;
    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );
    assertEq(proposal.cancellationFee, 0);
    assertEq(balanceBefore, balanceAfter + CANCELLATION_FEE);
    assertEq(balanceNow, balanceBefore);
  }

  function testRedeemWhenProposalCancelled() public {
    uint256 balanceBefore = address(this).balance;
    uint256 balanceBeforeCollector = CANCELLATION_FEE_COLLECTOR.balance;
    uint256 proposalId = _createProposal();

    assertEq(address(governance).balance, CANCELLATION_FEE);
    uint256 balanceAfter = address(this).balance;

    _activateVote(proposalId);

    governance.cancelProposal(proposalId);

    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;

    vm.expectEmit(true, true, true, true);
    emit CancellationFeeRedeemed(
      proposalId,
      CANCELLATION_FEE_COLLECTOR,
      CANCELLATION_FEE,
      true
    );
    governance.redeemCancellationFee(proposalIds);
    uint256 balanceAfterCollector = CANCELLATION_FEE_COLLECTOR.balance;

    uint256 balanceNow = address(this).balance;
    IGovernanceCore.Proposal memory proposalAfter = governance.getProposal(
      proposalId
    );
    assertEq(proposalAfter.cancellationFee, 0);
    assertEq(balanceBefore, balanceAfter + CANCELLATION_FEE);
    assertEq(balanceNow, balanceAfter);
    assertEq(balanceBeforeCollector, balanceAfterCollector - CANCELLATION_FEE);
  }

  function testRedeemWhenProposalExecuted() public {
    uint256 balanceBefore = address(this).balance;
    uint256 proposalId = _createProposal();

    assertEq(address(governance).balance, CANCELLATION_FEE);
    uint256 balanceAfter = address(this).balance;

    _activateVote(proposalId);
    _queueProposal(proposalId);
    _executeProposal(proposalId);

    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;

    vm.expectEmit(true, true, true, true);
    emit CancellationFeeRedeemed(
      proposalId,
      address(this),
      CANCELLATION_FEE,
      true
    );
    governance.redeemCancellationFee(proposalIds);

    uint256 balanceNow = address(this).balance;
    IGovernanceCore.Proposal memory proposalAfter = governance.getProposal(
      proposalId
    );
    assertEq(proposalAfter.cancellationFee, 0);
    assertEq(balanceBefore, balanceAfter + CANCELLATION_FEE);
    assertEq(balanceNow, balanceBefore);
  }

  function testRedeemWhenProposalExecutedAndFeeUpdated() public {
    uint256 balanceBefore = address(this).balance;
    uint256 proposalId = _createProposal();

    assertEq(address(governance).balance, CANCELLATION_FEE);
    uint256 balanceAfter = address(this).balance;

    _activateVote(proposalId);
    _queueProposal(proposalId);
    _executeProposal(proposalId);

    uint256 newCancellationFee = 1 ether;
    hoax(OWNER);
    governance.updateCancellationFee(newCancellationFee);

    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;

    vm.expectEmit(true, true, true, true);
    emit CancellationFeeRedeemed(
      proposalId,
      address(this),
      CANCELLATION_FEE,
      true
    );
    governance.redeemCancellationFee(proposalIds);

    uint256 balanceNow = address(this).balance;
    IGovernanceCore.Proposal memory proposalAfter = governance.getProposal(
      proposalId
    );
    assertEq(proposalAfter.cancellationFee, 0);
    assertEq(balanceBefore, balanceAfter + CANCELLATION_FEE);
    assertEq(balanceNow, balanceBefore);
  }

  function testRedeemWhenProposalExpired() public {
    uint256 balanceBefore = address(this).balance;
    uint256 proposalId = _createProposal();

    assertEq(address(governance).balance, CANCELLATION_FEE);
    uint256 balanceAfter = address(this).balance;
    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );
    skip(proposal.creationTime + governance.PROPOSAL_EXPIRATION_TIME() + 1);

    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;

    vm.expectEmit(true, true, true, true);
    emit CancellationFeeRedeemed(
      proposalId,
      address(this),
      CANCELLATION_FEE,
      true
    );
    governance.redeemCancellationFee(proposalIds);

    uint256 balanceNow = address(this).balance;
    IGovernanceCore.Proposal memory proposalAfter = governance.getProposal(
      proposalId
    );
    assertEq(proposalAfter.cancellationFee, 0);
    assertEq(balanceBefore, balanceAfter + CANCELLATION_FEE);
    assertEq(balanceNow, balanceBefore);
  }

  function testRedeemWhenProposalFailed() public {
    uint256 balanceBefore = address(this).balance;
    uint256 proposalId = _createProposal();

    assertEq(address(governance).balance, CANCELLATION_FEE);
    uint256 balanceAfter = address(this).balance;

    _activateVote(proposalId);

    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );

    uint128 forVotes = 1 ether;
    uint128 againstVotes = 1000000 ether;

    skip(proposal.votingDuration + proposal.votingActivationTime + 1);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    hoax(VOTING_PORTAL);
    governance.queueProposal(proposalId, forVotes, againstVotes);

    vm.clearMockedCalls();

    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;

    vm.expectEmit(true, true, true, true);
    emit CancellationFeeRedeemed(
      proposalId,
      address(this),
      CANCELLATION_FEE,
      true
    );
    governance.redeemCancellationFee(proposalIds);

    uint256 balanceNow = address(this).balance;
    IGovernanceCore.Proposal memory proposalAfter = governance.getProposal(
      proposalId
    );
    assertEq(proposalAfter.cancellationFee, 0);
    assertEq(balanceBefore, balanceAfter + CANCELLATION_FEE);
    assertEq(balanceNow, balanceBefore);
  }

  // UPDATE CANCELLATION FEE
  function testUpdateCancellationFee() public {
    uint256 newCancellationFee = 1 ether;

    hoax(OWNER);
    vm.expectEmit(false, false, false, true);
    emit CancellationFeeUpdated(newCancellationFee);
    governance.updateCancellationFee(newCancellationFee);

    assertEq(governance.getCancellationFee(), newCancellationFee);
  }

  function testUpdateCancellationFeeWhenNotOwner() public {
    uint256 newCancellationFee = 1 ether;

    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    governance.updateCancellationFee(newCancellationFee);
  }

  // GET PROPOSAL STATE
  function testGetProposalState() public {
    uint256 proposalId = _createProposal();

    IGovernanceCore.State proposalState = governance.getProposalState(
      proposalId
    );

    assertTrue(proposalState == IGovernanceCore.State.Created);
  }

  function testGetProposalStateNotExisting() public {
    IGovernanceCore.State proposalState = governance.getProposalState(1234);

    assertTrue(proposalState == IGovernanceCore.State.Null);
  }

  // UPDATE REPRESENTATIVES
  function testUpdateRepresentativesForChain() public {
    uint256 chainId1 = ChainIds.ETHEREUM;
    uint256 chainId2 = ChainIds.POLYGON;
    uint256 chainId3 = ChainIds.METIS;
    address voter = address(918237);
    address representative1 = address(9182372);
    address representative2 = address(9182373);
    address representative3 = address(9182374);

    assertEq(governance.getRepresentativeByChain(voter, chainId1), address(0));
    assertEq(governance.getRepresentativeByChain(voter, chainId2), address(0));

    IGovernanceCore.RepresentativeInput[]
      memory representatives = new IGovernanceCore.RepresentativeInput[](3);
    representatives[0] = IGovernanceCore.RepresentativeInput({
      representative: representative1,
      chainId: chainId1
    });
    representatives[1] = IGovernanceCore.RepresentativeInput({
      representative: representative2,
      chainId: chainId2
    });
    representatives[2] = IGovernanceCore.RepresentativeInput({
      representative: voter,
      chainId: chainId3
    });

    hoax(voter);
    vm.expectEmit(true, true, true, true);
    emit RepresentativeUpdated(voter, representative1, chainId1);
    vm.expectEmit(true, true, true, true);
    emit RepresentativeUpdated(voter, representative2, chainId2);
    vm.expectEmit(true, true, true, true);
    emit RepresentativeUpdated(voter, address(0), chainId3);
    governance.updateRepresentativesForChain(representatives);

    address[] memory representedVoters1 = governance
      .getRepresentedVotersByChain(representative1, chainId1);
    address[] memory representedVoters2 = governance
      .getRepresentedVotersByChain(representative2, chainId2);
    address[] memory representedVoters3 = governance
      .getRepresentedVotersByChain(voter, chainId3);

    assertEq(representedVoters1.length, 1);
    assertEq(representedVoters1[0], voter);

    assertEq(representedVoters2.length, 1);
    assertEq(representedVoters2[0], voter);

    assertEq(representedVoters3.length, 0);

    assertEq(
      governance.getRepresentativeByChain(voter, chainId1),
      representative1
    );
    assertEq(
      governance.getRepresentativeByChain(voter, chainId2),
      representative2
    );
    assertEq(governance.getRepresentativeByChain(voter, chainId3), address(0));

    // remove representative1
    representatives[0] = IGovernanceCore.RepresentativeInput({
      representative: address(0),
      chainId: chainId1
    });
    representatives[1] = IGovernanceCore.RepresentativeInput({
      representative: representative3,
      chainId: chainId2
    });

    hoax(voter);
    governance.updateRepresentativesForChain(representatives);

    representedVoters1 = governance.getRepresentedVotersByChain(
      representative1,
      chainId1
    );
    representedVoters2 = governance.getRepresentedVotersByChain(
      representative2,
      chainId2
    );
    address[] memory representedVoters = governance.getRepresentedVotersByChain(
      representative3,
      chainId2
    );

    assertEq(representedVoters1.length, 0);

    assertEq(representedVoters2.length, 0);

    assertEq(representedVoters.length, 1);
    assertEq(representedVoters[0], voter);
  }

  // HELPER METHODS
  function _createPayload(
    PayloadsControllerUtils.AccessControl level
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        chain: ChainIds.POLYGON,
        accessLevel: level,
        payloadsController: address(123012491456),
        payloadId: uint40(0)
      });
    return payload;
  }

  function _activateVote(uint256 proposalId) internal {
    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );
    IGovernanceCore.VotingConfig memory config = governance.getVotingConfig(
      proposal.payloads[0].accessLevel
    );
    skip(config.coolDownBeforeVotingStart + 1);
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(1000000 ether)
    );
    governance.activateVoting(proposalId);
  }

  function _createProposal() internal returns (uint256) {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_1;
    PayloadsControllerUtils.Payload[]
      memory payloads = new PayloadsControllerUtils.Payload[](1);
    PayloadsControllerUtils.Payload memory payload = _createPayload(
      accessLevel
    );
    payloads[0] = payload;

    bytes32 ipfsHash = keccak256(bytes('some ipfs hash'));
    bytes32 blockHash = blockhash(block.number - 1);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    vm.mockCall(
      VOTING_PORTAL,
      abi.encodeWithSelector(
        IVotingPortal.forwardStartVotingMessage.selector,
        0,
        blockHash,
        votingConfigLvl1.votingDuration
      ),
      abi.encode()
    );

    uint256 proposalId = governance.createProposal{value: CANCELLATION_FEE}(
      payloads,
      VOTING_PORTAL,
      ipfsHash
    );

    vm.clearMockedCalls();
    return proposalId;
  }

  function _queueProposal(uint256 proposalId) internal {
    IGovernanceCore.Proposal memory proposal = governance.getProposal(
      proposalId
    );

    uint128 forVotes = 1000000 ether;
    uint128 againstVotes = 1 ether;

    skip(proposal.votingDuration + proposal.votingActivationTime + 1);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    hoax(VOTING_PORTAL);
    governance.queueProposal(proposalId, forVotes, againstVotes);

    vm.clearMockedCalls();
  }

  function _executeProposal(uint256 proposalId) internal {
    IGovernanceCore.Proposal memory preProposal = governance.getProposal(
      proposalId
    );

    skip(
      block.timestamp +
        preProposal.queuingTime +
        governance.COOLDOWN_PERIOD() +
        10
    );

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils
      .Payload({
        chain: preProposal.payloads[0].chain,
        accessLevel: preProposal.payloads[0].accessLevel,
        payloadsController: preProposal.payloads[0].payloadsController,
        payloadId: preProposal.payloads[0].payloadId
      });

    bytes memory messageWithType = BridgingHelper.encodePayloadExecutionMessage(
      payload,
      preProposal.votingActivationTime
    );

    vm.mockCall(
      CROSS_CHAIN_CONTROLLER,
      abi.encodeWithSelector(
        ICrossChainForwarder.forwardMessage.selector,
        preProposal.payloads[0].chain,
        preProposal.payloads[0].payloadsController,
        EXECUTION_GAS_LIMIT,
        messageWithType
      ),
      abi.encode(bytes32(0), bytes32(0))
    );

    governance.executeProposal(proposalId);

    vm.clearMockedCalls();
  }

  receive() external payable {}
}
