import { BigNumber, ethers } from "ethers";
import {
  defaultAbiCoder,
  hexStripZeros,
  hexZeroPad,
  keccak256,
} from "ethers/lib/utils.js";

export function formatToProofRLP(rawData) {
  return ethers.utils.RLP.encode(
    rawData.map((d) => ethers.utils.RLP.decode(d))
  );
}

export const getProof = async (
  provider, //: providers.StaticJsonRpcProvider,
  address, //: string,
  storageKeys, //: string[],
  blockNumber //: number
) => {
  return await provider.send("eth_getProof", [
    address,
    storageKeys,
    BigNumber.from(blockNumber).toHexString(),
  ]);
};

export const getExtendedBlock = async (
  provider, //: providers.StaticJsonRpcProvider,
  blockNumber //: number
) => {
  return provider.send("eth_getBlockByNumber", [
    BigNumber.from(blockNumber).toHexString(),
    false,
  ]);
};

// IMPORTANT valid only for post-London blocks, as it includes `baseFeePerGas`
export function prepareBLockRLP(rawBlock) {
  const rawData = [
    rawBlock.parentHash,
    rawBlock.sha3Uncles,
    rawBlock.miner,
    rawBlock.stateRoot,
    rawBlock.transactionsRoot,
    rawBlock.receiptsRoot,
    rawBlock.logsBloom,
    "0x", //BigNumber.from(rawBlock.difficulty).toHexString(),
    BigNumber.from(rawBlock.number).toHexString(),
    BigNumber.from(rawBlock.gasLimit).toHexString(),
    rawBlock.gasUsed === "0x0"
      ? "0x"
      : BigNumber.from(rawBlock.gasUsed).toHexString(),
    BigNumber.from(rawBlock.timestamp).toHexString(),
    rawBlock.extraData,
    rawBlock.mixHash,
    rawBlock.nonce,
    BigNumber.from(rawBlock.baseFeePerGas).toHexString(),
    rawBlock.withdrawalsRoot,
  ];
  return ethers.utils.RLP.encode(rawData);
}

export function getSolidityStorageSlotArrayBytes(
  arraySlot, //: BytesLike,
  key //: number
) {
  const hashedBaseSlot = hexStripZeros(
    keccak256(defaultAbiCoder.encode(["uint256"], [hexZeroPad(arraySlot, 32)]))
  );
  return hexZeroPad(BigNumber.from(hashedBaseSlot).add(key).toHexString(), 32);
}

export function getSolidityStorageSlotBytes(
  mappingSlot, //: BytesLike,
  key //: string
) {
  const slot = hexZeroPad(mappingSlot, 32);
  return hexStripZeros(
    keccak256(defaultAbiCoder.encode(["address", "uint256"], [key, slot]))
  );
}

export function getSolidityTwoLevelStorageSlotHash(
  rawSlot, //number
  voter, // string
  chainId // number
) {
  const abiCoder = new ethers.utils.AbiCoder();
  // ABI Encode the first level of the mapping
  // abi.encode(address(voter), uint256(MAPPING_SLOT))
  // The keccak256 of this value will be the "slot" of the inner mapping
  const firstLevelEncoded = abiCoder.encode(
    ["address", "uint256"],
    [voter, ethers.BigNumber.from(rawSlot)]
  );

  // ABI Encode the second level of the mapping
  // abi.encode(uint256(chainId))
  const secondLevelEncoded = abiCoder.encode(
    ["uint256"],
    [ethers.BigNumber.from(chainId)]
  );

  // Compute the storage slot of [address][uint256]
  // keccak256(abi.encode(uint256(chainId)) . abi.encode(address(voter), uint256(MAPPING_SLOT)))
  return ethers.utils.keccak256(
    ethers.utils.concat([
      secondLevelEncoded,
      ethers.utils.keccak256(firstLevelEncoded),
    ])
  );
}
