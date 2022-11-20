/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
*/

// @imports
import { ethers } from 'hardhat';
import { NAVTIVE_TOKEN_WRAPPER } from '../../utils/constants';
import { exportArtifactsToClient } from '../../utils/exportArtifactsToClient';

/**
 * @dev deploy SwylClub smart contract
 */
const D_SwylClub = async () => {
  console.log(`Start deploying SwylClub...`);
  // prepare SwylClub SC
  const SwylClub = await ethers.getContractFactory('SwylClub');
  // asyncly deploy SwylClub SC
  const swylClub = await SwylClub.deploy(NAVTIVE_TOKEN_WRAPPER);
  await swylClub.deployed();
  console.log(`SwylClub deployed to the address: ${swylClub.address}`);

  // export contract artifacts to client folder
  exportArtifactsToClient(swylClub, 'SwylClub');
};

export default D_SwylClub;
