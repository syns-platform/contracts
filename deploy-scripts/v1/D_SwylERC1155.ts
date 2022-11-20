/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
*/

// @imports
import { ethers } from 'hardhat';

import { exportArtifactsToClient } from '../../utils/exportArtifactsToClient';
import {
  SWYL_NFT_NAME,
  SWYL_NFT_SYMBOL,
  SWYL_NFT_SERVICE_RECIPIENT,
  SWYL_NFT_DEFAULT_ROYALTY_BPS,
} from '../../utils/constants';

/**
 * @dev deploy swylERC721 smart contract
 */
const D_SwylERC1155 = async () => {
  console.log(`Start deploying SwylERC1155...`);
  // prepare SwylERC1155 SC
  const SwylERC1155 = await ethers.getContractFactory('SwylERC1155');
  // asyncly deploy SwylERC1155 SC
  const swylERC1155 = await SwylERC1155.deploy();
  await swylERC1155.deployed();
  console.log(`SwylERC1155 deployed to the address: ${swylERC1155.address}`);

  // export contract artifacts to client folder
  exportArtifactsToClient(swylERC1155, 'SwylERC1155');
};

export default D_SwylERC1155;
