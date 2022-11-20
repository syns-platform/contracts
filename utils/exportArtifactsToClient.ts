/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
*/

// @imports
import { Contract } from 'ethers';
import { artifacts } from 'hardhat';

/**
 * @dev exports smart contract artifacts to client folder
 *
 * @NOTE only works with this specific folder setup
 *
 * @param contract
 *
 * @param name
 */
export const exportArtifactsToClient = (contract: Contract, name: string) => {
  console.log(`exporting contract artifacts to client...`);
  // prepare contractArtifactsDir
  const fs = require('fs');
  const contractArtifactsDir = `${__dirname}/../../client/contract-artifacts`;

  // make dir if not exists
  if (!fs.existsSync(contractArtifactsDir)) {
    fs.mkdirSync(contractArtifactsDir);
  }

  // write contract address to a new file
  fs.writeFileSync(
    `${contractArtifactsDir}/${name}Address.json`,
    JSON.stringify({ address: contract.address }, undefined, 2)
  );

  // prepare contractAritifact
  const contractAritifact = artifacts.readArtifactSync(name);

  fs.writeFileSync(
    `${contractArtifactsDir}/${name}.json`,
    JSON.stringify(contractAritifact, null, 2)
  );
  console.log(`done.`);
};
