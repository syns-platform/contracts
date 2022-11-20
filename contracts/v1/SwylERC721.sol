/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
    @Hornor: Thirdweb & Openzeppeline
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/** EXTERNAL IMPORT */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


/**
 *  The `SwylERC721` smart contract implements the Openzeppelin/ERC721 NFT standard, along with the ERC721Royalty optimization.
 *  It includes all the standard logics from ERC721A & ERC721Base PLUS:
 *      - Emit event mintedTo() everytime mintTo() is called
 *      - Records the original creator of the NFT by adding the original creator's address to a mapping
 */
contract SwylERC721 is ERC721URIStorage, ERC721Royalty, AccessControl {
    /*//////////////////////////////////////////////////////////////
                        Variables
    //////////////////////////////////////////////////////////////*/
    // States
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // structs
    struct RoyaltyInfoForAddress {
        address originalAuthor;
        uint96 royaltyBPS;
    }

    // Mapping(s) tokenID => originalCreator => royaltyBPS
    mapping (uint256 => RoyaltyInfoForAddress) private royaltyInfoForToken;

    // Event(s)
    event mintedTo(address _to, string uri);

    /*//////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/
    constructor() ERC721("Support Who You Love", "SWYL721") {
        // grant admin role to deployer
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        SwylERC721v1 Logic
    //////////////////////////////////////////////////////////////*/

     /**
     *  @notice             Lets any addresses mint an NFT to themselves or to another recepient. Override @erc721a.mintTo()
     *  @dev                After finished minting new token, _setupRoyaltyInfoForToken() is called to set the originalCreator as
     *                      royalty recipient address
     *
     *  @param _tokenURI    The token uri
     */
     function safeMintTo(string memory _tokenURI, uint96 _royaltyBps) public returns (uint) {
        // prepare nextTokenIdToMint
        uint256 nextTokenIdToMint = _tokenIds.current();

        // mint a new token
        _safeMint(msg.sender, nextTokenIdToMint);
        _setTokenURI(nextTokenIdToMint, _tokenURI);

        // update RoyaltyInfoForToken mapping
        RoyaltyInfoForAddress memory currentRoyaltyInfo = RoyaltyInfoForAddress({
            originalAuthor: msg.sender,
            royaltyBPS: _royaltyBps}
        );
        royaltyInfoForToken[nextTokenIdToMint] = currentRoyaltyInfo;

        // set roytalty recipient for token
        _setTokenRoyalty(nextTokenIdToMint, msg.sender, _royaltyBps);

        // increment tokenId
        _tokenIds.increment();

        return nextTokenIdToMint;
    }


    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                        SwylERC721v1 Getters
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns originalCreator by tokenId
    function getRoyaltyInfoForToken(uint _tokenId) view public returns (RoyaltyInfoForAddress memory) {
        return royaltyInfoForToken[_tokenId];
    }

    /// @dev Returns Royalty Token Information based on 
    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) public view returns (address, uint256) {
        
    }
}