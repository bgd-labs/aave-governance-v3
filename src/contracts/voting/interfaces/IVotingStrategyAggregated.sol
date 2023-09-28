// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingStrategy} from './IVotingStrategy.sol';
import {IBaseVotingStrategy} from '../../../interfaces/IBaseVotingStrategy.sol';

/**
 * @title IVotingStrategyAggregated
 * @author BGD Labs
 * @notice Interface helper that aggregates all L1 voting strategy interfaces, so its easy to use
           when casting the voting strategy address
 */
interface IVotingStrategyAggregated is IBaseVotingStrategy, IVotingStrategy {

}
