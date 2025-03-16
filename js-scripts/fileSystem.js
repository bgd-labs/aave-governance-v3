import * as fs from "fs";

export const saveJson = (stringifiedJson, path) => {
  fs.writeFileSync(path, stringifiedJson);
};

export const getProofsJson = (path) => {
  try {
    const file = fs.readFileSync(path);
    // @ts-ignore
    return JSON.parse(file);
  } catch (error) {
    return {};
  }
};
