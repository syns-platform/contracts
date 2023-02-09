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
 * @dev deploy synsERC721 smart contract
 */
const D_SynsERC721 = async () => {
  console.log(`Start deploying SynsERC721...`);
  // prepare SynsERC721 SC
  const SynsERC721 = await ethers.getContractFactory('SynsERC721');

  // asyncly deploy SynsERC721 SC
  const synsERC721 = await SynsERC721.deploy();
  await synsERC721.deployed();
  console.log(`SynsERC721 deployed to the address: ${synsERC721.address}`);

  // export contract artifacts to client folder
  exportArtifactsToClient(synsERC721, 'SynsERC721');
};

export default D_SynsERC721;
