/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
    @Hornor: Thirdweb & Openzeppeline
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** EXTERNAL IMPORT */
import "@thirdweb-dev/contracts/base/ERC1155Base.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

/**
 *  The `SwylERC1155` smart contract implements the Thirdweb/ERC1155Base NFT standard.
 *  It includes all the standard logic from ERC1155 PLUS:
 *      - Emit event newTokenMintedTo (if a new token is minted) everytime mintTo() is called
 *      - Emit event mintedOnExistedToken (if more supply is added to an existed token) everytime mintTo() is called
 *      - Records the original creator of the NFT when a new token is created by adding the original creator's address to a mapping
 */
contract SwylERC1155 is ERC1155Base, PermissionsEnumerable {
    /*//////////////////////////////////////////////////////////////
                        Variables
    //////////////////////////////////////////////////////////////*/
    // Mapping(s)
            mapping (uint256 => address) private tokenIdToOriginalCreator;

    // Event(s)
    event newTokenMintedTo(address _to, uint256 _tokenId, string uri, uint256 amount);
    event mintedOnExistedToken(address _to, uint256 _tokenId, string uri, uint256 amount);


    /*//////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/
      constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    )
        ERC1155Base(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {
        // grant admin role to deployer
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /*//////////////////////////////////////////////////////////////
                        SwylERC1155v1 Logic
    //////////////////////////////////////////////////////////////*/
    
    /**
     *  @notice          Lets an authorized address mint NFTs to a recipient.
     *  @dev             - The logic in the `super._canMint()` function determines whether the caller is authorized to mint NFTs.
     *                   - If `_tokenId == getNewTokenRequiredId()` 
     *                          + A new NFT is created at tokenId `nextTokenIdToMint` is minted.
     *                          + Set the royalty recipient to the address _to
     *                          + Emits event newTokenMintedTo().
     *                   - If the given `tokenId < nextTokenIdToMint`, then additional supply of an existing NFT is being minted
     *                      on existed token at _tokenId, and the tokenURI is set to be the same. 
     *                      Emits event mintedOnExistedToken().
     *
     *  @param _to       The recipient of the NFTs to mint.
     *  @param _tokenId  The tokenId of the NFT to mint.
     *  @param _tokenURI The full metadata URI for the NFTs minted (if a new NFT is being minted).
     *  @param _amount   The amount of the same NFT to mint.
     */
    function safeMintTo(
        address _to, 
        uint256 _tokenId, 
        string memory _tokenURI, 
        uint256 _amount,
        uint256 _bps
    ) public onlyRole(DEFAULT_ADMIN_ROLE){
        // newTokenRequiredId is the ID that _tokenId must meet to create a new token. Otherwise, more supply are minted on existed tokens.
        uint newTokenRequiredId = getNewTokenRequiredId();

        // nextTokenIdToMint is the new tokenId of the new token being created.
        uint nextTokenIdToMint = super.nextTokenIdToMint();

        // Calls mintTo() from ERC1155Base
        super.mintTo(_to, _tokenId, _tokenURI, _amount);


        // originalCreator logic
        if (_tokenId == newTokenRequiredId) { // new token is being created
            tokenIdToOriginalCreator[nextTokenIdToMint] = _to;
            _setupRoyaltyInfoForToken(nextTokenIdToMint, _to, _bps);
            emit newTokenMintedTo(_to, nextTokenIdToMint, _tokenURI, _amount);
        } else { // more supplies are being minted on an existed token
            emit mintedOnExistedToken(_to, nextTokenIdToMint, _tokenURI, _amount);
        }
    }


    /*//////////////////////////////////////////////////////////////
                        SwylERC1155v1 Getters
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the biggest uint256 value to set a bar for creating a new token
    function getNewTokenRequiredId() pure public returns (uint256) {
        return type(uint256).max;
    }

    /// @dev Returns originalCreator by tokenId
    function getOriginalCreator(uint _tokenId) view public returns (address) {
        return tokenIdToOriginalCreator[_tokenId];
    }
}