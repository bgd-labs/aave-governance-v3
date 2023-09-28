// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {MockToImport} from './mock/MockCrossChainInfra.sol';

contract TestMockTest is Test {
  using stdJson for string;

  address t;

  struct Addresses {
    address proxyFactory;
    address proxyAdmin;
  }

  function setUp() public {
    t = address(new MockToImport());
  }

  //  function testJson() public {
  //    string memory json = vm.readFile('./deployments/multiChainPipeline.json');
  //    string memory ethereum = 'ethereum';
  //    string memory avalanche = 'avalanche';
  //
  //    console.log('json', json);
  //
  //    bytes memory ethereumBytes = json.parseRaw('.ethereum');
  //    Addresses memory ethereumAddresses = abi.decode(ethereumBytes, (Addresses));
  //
  //    ethereum.serialize('proxyFactory', ethereumAddresses.proxyFactory);
  //    ethereum = ethereum.serialize('proxyAdmin', ethereumAddresses.proxyAdmin);
  //
  //    //
  //    avalanche.serialize('proxyFactory', address(1));
  //    avalanche = avalanche.serialize('proxyAdmin', address(2));
  //
  //    string memory deployments = 'deployments';
  //    deployments.serialize('ethereum', ethereum);
  //    deployments = deployments.serialize('avalanche', avalanche);
  //    console.log('final', deployments);
  //    //    vm.writeJson(deployedJson, './deployments/multiChainPipeline.json');
  //  }
}
