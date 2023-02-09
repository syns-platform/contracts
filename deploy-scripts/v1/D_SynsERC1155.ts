/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
*/

// @imports
import { ethers } from 'hardhat';

import { exportArtifactsToClient } from '../../utils/exportArtifactsToClient';

/**
 * @dev deploy SynsERC721 smart contract
 */
const D_SynsERC1155 = async () => {
  console.log(`Start deploying SynsERC1155...`);
  // prepare SynsERC1155 SC
  const SynsERC1155 = await ethers.getContractFactory('SynsERC1155');

  // asyncly deploy SynsERC1155 SC
  const synsERC1155 = await SynsERC1155.deploy();
  await synsERC1155.deployed();
  console.log(`SynsERC1155 deployed to the address: ${synsERC1155.address}`);

  // export contract artifacts to client folder
  exportArtifactsToClient(synsERC1155, 'SynsERC1155');
};

export default D_SynsERC1155;
