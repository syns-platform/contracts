/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
    @Honor: Thirdweb & Openzeppeline
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

//  ==========  Internal imports    ==========

import { IMarketplace } from "@thirdweb-dev/contracts/interfaces/marketplace/IMarketplace.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";
import "@thirdweb-dev/contracts/lib/FeeType.sol";

contract MarketplaceSwylV5 is
    Initializable,
    IMarketplace,
{ 
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("Marketplace");
    uint256 private constant VERSION = 2;

    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 private constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be listed, when listings are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The address of the native token wrapper contract.
    address private immutable nativeTokenWrapper;

    /// @dev Total number of listings ever created in the marketplace.
    uint256 public totalListings;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev The address that receives all platform fees from all sales.
    address private platformFeeRecipient;

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 public constant MAX_BPS = 10_000;

    /// @dev The % of primary sales collected as platform fees.
    uint64 private platformFeeBps;

    /// @dev
    /**
     *  @dev The amount of time added to an auction's 'endTime', if a bid is made within `timeBuffer`
     *       seconds of the existing `endTime`. Default: 15 minutes.
     */
    uint64 public timeBuffer;

    /// @dev The minimum % increase required from the previous winning bid. Default: 5%.
    uint64 public bidBufferBps;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from uid of listing => listing info.
    mapping(uint256 => Listing) public listings;

    /// @dev Mapping from uid of a direct listing => offeror address => offer made to the direct listing by the respective offeror.
    mapping(uint256 => mapping(address => Offer)) public offers;

    /// @dev Mapping from uid of an auction listing => current winning bid in an auction.
    mapping(uint256 => Offer) public winningBid;

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether caller is a listing creator.
    modifier onlyListingCreator(uint256 _listingId) {
        require(listings[_listingId].tokenOwner == _msgSender(), "!OWNER");
        _;
    }

    /// @dev Checks whether a listing exists.
    modifier onlyExistingListing(uint256 _listingId) {
        require(listings[_listingId].assetContract != address(0), "DNE");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _nativeTokenWrapper) initializer {
        nativeTokenWrapper = _nativeTokenWrapper;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(LISTER_ROLE, address(0));
        _setupRole(ASSET_ROLE, address(0));
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _platformFeeRecipient,
        uint256 _platformFeeBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);

        // Initialize this contract's state.
        timeBuffer = 15 minutes;
        bidBufferBps = 500;

        contractURI = _contractURI;
        platformFeeBps = uint64(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(LISTER_ROLE, address(0));
        _setupRole(ASSET_ROLE, address(0));
    }


    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
