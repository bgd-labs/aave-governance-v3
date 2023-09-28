// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

contract PayloadTest {
  event SimpleExecute(string);
  event ComplexExecute(string, uint256);

  function execute() external {
    emit SimpleExecute('simple');
  }

  function complexExecute(uint256 number) external {
    emit ComplexExecute('complex', number);
  }
}
