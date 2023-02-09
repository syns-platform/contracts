import D_SynsClub from './D_SynsClub';
import D_SynsDonation from './D_SynsDonation';
import D_SynsERC721 from './D_SynsERC721';
import D_SynsERC1155 from './D_SynsERC1155';
import D_SynsMatketplace from './D_SynsMatketplace';

const main = async () => {
  await D_SynsClub();
  await D_SynsDonation();
  await D_SynsERC721();
  await D_SynsERC1155();
  await D_SynsMatketplace();
};

main().catch((e: any) => {
  console.error(e);
  process.exitCode = 1;
});
