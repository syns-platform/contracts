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
 * @dev deploy SynsClub smart contract
 */
const D_SynsClub = async () => {
  console.log(`Start deploying SynsClub...`);

  // prepare SynsClub SC
  const SynsClub = await ethers.getContractFactory('SynsClub');

  // asyncly deploy SynsClub SC
  const synsClub = await SynsClub.deploy(NAVTIVE_TOKEN_WRAPPER);
  await synsClub.deployed();
  console.log(`SynsClub deployed to the address: ${synsClub.address}`);

  // export contract artifacts to client folder
  exportArtifactsToClient(synsClub, 'SynsClub');
};

export default D_SynsClub;
