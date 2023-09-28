import * as fs from "fs";

export const saveJson = (stringifiedJson) => {
  fs.writeFileSync("tests/utils/proofs.json", stringifiedJson);
};

export const getProofsJson = () => {
  try {
    const file = fs.readFileSync("tests/utils/proofs.json");
    // @ts-ignore
    return JSON.parse(file);
  } catch (error) {
    return {};
  }
};
