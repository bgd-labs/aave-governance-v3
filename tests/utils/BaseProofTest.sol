// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/StdJson.sol';
import 'forge-std/Test.sol';
import {IDataWarehouse} from '../../src/contracts/voting/interfaces/IDataWarehouse.sol';
import {DataWarehouse} from '../../src/contracts/voting/DataWarehouse.sol';
import {IVotingStrategy} from '../../src/contracts/voting/interfaces/IVotingStrategy.sol';
import {VotingStrategy, IBaseVotingStrategy} from '../../src/contracts/voting/VotingStrategy.sol';
import {VotingStrategyTest} from '../../scripts/extendedContracts/StrategiesTest.sol';

contract BaseProofTest is Test {
  using stdJson for string;

  address AAVE;
  address A_AAVE;
  address STK_AAVE;

  address GOVERNANCE;

  IDataWarehouse dataWarehouse;
  IVotingStrategy votingStrategy;

  AaveProofs aaveProofs;
  AAaveProofs aAaveProofs;
  StkAaveProofs stkAaveProofs;
  RepresentativesProofs representatives;

  bytes32 proofBlockHash;
  address proofVoter;

  // Structs need to be ordered as they are used to parse json
  struct AaveProofs {
    bytes accountStateProofRLP;
    uint256 balance;
    uint256 balanceSlotValue;
    bytes balanceStorageProofRlp;
    bytes32 baseBalanceSlot;
    uint256 baseBalanceSlotRaw;
    bytes blockHeaderRLP;
    bool delegating;
    address token;
    uint256 votingPower;
  }
  struct AAaveProofs {
    bytes aAaveDelegationStorageProofRlp;
    bytes accountStateProofRLP;
    uint256 balance;
    uint256 balanceSlotValue;
    bytes balanceStorageProofRlp;
    bytes32 baseBalanceSlot;
    uint256 baseBalanceSlotRaw;
    bytes blockHeaderRLP;
    bool delegating;
    bytes32 delegationBalanceSlot;
    uint256 delegationBalanceSlotValue;
    uint256 delegationSlotRaw;
    address token;
    uint256 votingPower;
  }
  struct StkAaveProofs {
    bytes accountStateProofRLP;
    uint256 balance;
    uint256 balanceSlotValue;
    bytes balanceStorageProofRlp;
    bytes32 baseBalanceSlot;
    uint256 baseBalanceSlotRaw;
    bytes blockHeaderRLP;
    bool delegating;
    uint256 exchangeRate;
    uint256 exchangeRateSlotRaw;
    bytes32 stkAaveExchangeRateSlot;
    bytes stkAaveExchangeRateStorageProofRlp;
    address token;
    uint256 votingPower;
  }

  struct RepresentativesProofs {
    bytes accountStateProofRLP;
    bytes blockHeaderRLP;
    uint256 chainId;
    bytes proofOfRepresentative;
    uint256 representative;
    uint256 representativesSlot;
    uint256 representativesSlotHash;
    uint256 representativesSlotRaw;
    address represented;
    address token;
  }

  function _initializeAave() internal {
    _processRoots(
      AAVE,
      aaveProofs.blockHeaderRLP,
      aaveProofs.accountStateProofRLP
    );
  }

  function _initializeStkAave() internal {
    _processRoots(
      STK_AAVE,
      stkAaveProofs.blockHeaderRLP,
      stkAaveProofs.accountStateProofRLP
    );

    // process slot
    _processSlot(
      STK_AAVE,
      stkAaveProofs.stkAaveExchangeRateSlot,
      stkAaveProofs.stkAaveExchangeRateStorageProofRlp
    );
  }

  function _initializeAAave() internal {
    _processRoots(
      A_AAVE,
      aAaveProofs.blockHeaderRLP,
      aAaveProofs.accountStateProofRLP
    );
  }

  function _initializeRepresentatives() internal {
    _processRoots(
      GOVERNANCE,
      representatives.blockHeaderRLP,
      representatives.accountStateProofRLP
    );
  }

  function _initVotingStrategy() internal {
    votingStrategy = new VotingStrategyTest(address(dataWarehouse));
  }

  function _getRootsAndProofs() internal {
    string memory path = './tests/utils/proofs.json';

    string memory json = vm.readFile(string(abi.encodePacked(path)));

    address[] memory tokens = abi.decode(json.parseRaw('.tokens'), (address[]));

    for (uint256 i; i < tokens.length; i++) {
      if (tokens[i] == IBaseVotingStrategy(address(votingStrategy)).AAVE()) {
        aaveProofs = abi.decode(json.parseRaw('.AAVE'), (AaveProofs));
        AAVE = tokens[i];
      } else if (
        tokens[i] == IBaseVotingStrategy(address(votingStrategy)).STK_AAVE()
      ) {
        stkAaveProofs = abi.decode(json.parseRaw('.STK_AAVE'), (StkAaveProofs));
        STK_AAVE = tokens[i];
      } else if (
        tokens[i] == IBaseVotingStrategy(address(votingStrategy)).A_AAVE()
      ) {
        aAaveProofs = abi.decode(json.parseRaw('.A_AAVE'), (AAaveProofs));
        A_AAVE = tokens[i];
      }
    }

    representatives = abi.decode(
      json.parseRaw('.REPRESENTATIVES'),
      (RepresentativesProofs)
    );
    GOVERNANCE = abi.decode(json.parseRaw('.governance'), (address));

    proofBlockHash = abi.decode(json.parseRaw('.blockHash'), (bytes32));
    proofVoter = abi.decode(json.parseRaw('.voter'), (address));
  }

  function _processSlot(
    address account,
    bytes32 slot,
    bytes memory slotStorageProof
  ) internal {
    dataWarehouse.processStorageSlot(
      account,
      proofBlockHash,
      slot,
      slotStorageProof
    );
  }

  function _processRoots(
    address account,
    bytes memory blockHeaderRLP,
    bytes memory accountStateProofRLP
  ) internal {
    dataWarehouse.processStorageRoot(
      account,
      proofBlockHash,
      blockHeaderRLP,
      accountStateProofRLP
    );
  }
}
