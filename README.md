<p align="center">
<br />
<h1 align="center">SWYL - Support Who You Love</h1>
<h5>Work in progress...</h5>
</p>

## Overview

This repository contains a list of smart contracts written in [Solidity](https://soliditylang.org/) which power Swyl's logic on the [Polygon blockchain](https://polygon.technology/matic-token/). Specially as:

- `SwylERC721` - implements the [@Thirdweb](https://thirdweb.com/)/[ERC721Base](https://github.com/logann131/contracts/blob/main/contracts/base/ERC721Base.sol) NFT standard, along with the [ERC721A](https://www.erc721a.org/) optimization. `SwylERC721` includes all the NFT industry standards from ERC721A & ERC721Base PLUS `Swyl's logic`.

- `SwylERC1155` - implements the [@Thirdweb](https://thirdweb.com/)/[ERC1155Base](https://github.com/logann131/contracts/blob/main/contracts/base/ERC1155Base.sol) NFT standard. `SwylERC1155` includes all the NFT industry standards from ERC1155 PLUS `Swyl's logic`.

- `SwylMarketPlace` - comming soon...

- `SwylDonation` - comming soon...

- `SwylMembership` - comming soon...

## Building the project

```bash
npm run build
# or
yarn build
```

to compile your contracts. This will also detect the [Contracts Extensions Docs](https://portal.thirdweb.com/thirdweb-deploy/contract-extensions) detected on the contract.

## Deploying Contracts

```bash
npm run deploy
# or
yarn deploy
```

## Releasing Contracts

```bash
npm run release
# or
yarn release
```


## Resources / Honors
 - [Thirdweb](https://thirdweb.com/)
 - [OpenZeppelin](https://www.openzeppelin.com/)
