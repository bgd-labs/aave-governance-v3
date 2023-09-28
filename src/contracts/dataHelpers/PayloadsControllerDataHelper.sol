// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../payloads/PayloadsControllerUtils.sol';
import {IPayloadsController} from '../payloads/interfaces/IPayloadsController.sol';
import {IPayloadsControllerCore} from '../payloads/interfaces/IPayloadsControllerCore.sol';
import {IPayloadsControllerDataHelper} from './interfaces/IPayloadsControllerDataHelper.sol';

/**
 * @title PayloadsControllerDataHelper
 * @author BGD Labs
 * @notice this contract contains the logic to get the payloads and to retreive the executor configs.
 */
contract PayloadsControllerDataHelper is IPayloadsControllerDataHelper {
  /// @inheritdoc IPayloadsControllerDataHelper
  function getPayloadsData(
    IPayloadsController payloadsController,
    uint40[] calldata payloadsIds
  ) external view returns (Payload[] memory) {
    Payload[] memory payloads = new Payload[](payloadsIds.length);
    IPayloadsController.Payload memory payload;

    for (uint256 i = 0; i < payloadsIds.length; i++) {
      payload = payloadsController.getPayloadById(payloadsIds[i]);
      payloads[i] = Payload({id: payloadsIds[i], data: payload});
    }

    return payloads;
  }

  /// @inheritdoc IPayloadsControllerDataHelper
  function getExecutorConfigs(
    IPayloadsController payloadsController,
    PayloadsControllerUtils.AccessControl[] calldata accessLevels
  ) external view returns (ExecutorConfig[] memory) {
    ExecutorConfig[] memory executorConfigs = new ExecutorConfig[](
      accessLevels.length
    );
    IPayloadsControllerCore.ExecutorConfig memory executorConfig;

    for (uint256 i = 0; i < accessLevels.length; i++) {
      executorConfig = payloadsController.getExecutorSettingsByAccessControl(
        accessLevels[i]
      );
      executorConfigs[i] = ExecutorConfig({
        accessLevel: accessLevels[i],
        config: executorConfig
      });
    }

    return executorConfigs;
  }
}
