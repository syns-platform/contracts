// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/** EXTERNAL IMPORT */
import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

/**
 *  The `SwylERC721v1` smart contract implements the Thirdweb/ERC721Base NFT standard, along with the ERC721A optimization.
 *  It includes all the standard logics from ERC721A & ERC721Base PLUS:
 *      
 *      - Emit event mintedTo() everytime mintTo() is called
 * 
 *      - Records the original creator of the NFT by adding the original creator's address to a mapping
 */
contract SwylERC721v1 is ERC721Base, PermissionsEnumerable {
    /*//////////////////////////////////////////////////////////////
                        Variables
    //////////////////////////////////////////////////////////////*/
    // Mapping(s)
    mapping (uint256 => address) private tokenIdToOriginalCreator;

    // Event(s)
    event mintedTo(address _to, string uri);


    /*//////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721Base(
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
                        SwylERC721v1 Logic
    //////////////////////////////////////////////////////////////*/
    
    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient. Override @thirdweb/ERC721Base.mintTo()
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _tokenURI The full metadata URI for the NFT minted.
     */
    function mintTo(address _to, string memory _tokenURI) public override {
        // specify nextTokenIdToMint
        uint256 nextTokenIdToMint = super.nextTokenIdToMint();

        // "super" refers to the base contract.
        // the mintTo() in base contract using:
        //  - ERC721's _safeMint() 
        //  - ERC721Storage _setTokenURI() 
        // only contract owner can mint
        super.mintTo(_to, _tokenURI);

        // update tokenIdToOriginalCreator mapping
        tokenIdToOriginalCreator[nextTokenIdToMint] = _to;

        // emit event everytime mintTo is called
        emit mintedTo(_to, _tokenURI);
    }


    /*//////////////////////////////////////////////////////////////
                        SwylERC721v1 Getters
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns originalCreator by tokenId
    function getOriginalCreator(uint _tokenId) view public returns (address) {
        return tokenIdToOriginalCreator[_tokenId];
    }
}