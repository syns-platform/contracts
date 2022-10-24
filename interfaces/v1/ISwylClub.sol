/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwylClub {

    //  ==========  Struct(s)    ==========

    /**
    * @notice The information of a Club.
    *
s    * @param clubOwner      address - the address of the owner.
    *
    * @param date           uint256 - uinx timestamp when a Club is created.
    *
    * @param currency       address - The address of the currency to be used.
    *
    * @param tiers          Tier - an array of struct Tiers.
    */
    struct Club {
        address clubOwner;
        uint256 date;
        address currency;
        Tier[] tiers;
    }

    /** 
    * @notice The information of a tier plan.
    *
    * @param tierId         uin256 - the unique id of a tier
    *
    * @param tierFee        uin256 - the price per month of the tier.
    *
    * @param members        address[] - an array of members' address.
    *
    * @param sizeLimit      uint256 - an optional choice if club's owner wants to limit the size of a certain tier.
    *
    * @param tierData       string - the off-chain URI to the JSON typed metadata of the tier includes:
    *                                   (1) Tier's name
    *                                   (2) Tier's benefit
    *                                   (3) Tier's description
    *                                   (4) Tier's image
    *                                   (5) Tier's message
    */
    struct Tier {
        uint256 tierId;
        uint256 tierFee;
        address[] members;
        uint256 sizeLimit;
        string tierData;
    }


    /** 
    * @notice For use in `addeTier()` and `updateTier()` as a parameter type.
    *
    * @param tierFee        uint256 - the price per month of the tier.
    *
    * @param sizeLimit      uint256 - the size limit of the tier to be added.
    *
    * @param tierData       string - the URI to the metadata of the tier
    */
    struct TierAPIParam {
        uint256 tierFee;
        uint256 sizeLimit;
        string tierData;
    }
    
    /** 
    * @notice For use in `subscribe()` as a parameter type.
    *
    * @param clubId         uint256 - the uid of the Club holding the Tier to be subsribed.
    *
    * @param tierId         uint256 - the uid of the Tier to be subscribed.
    *
    * @param tierFee        uint256 - the amount the account is expected to cover to subscribe to the Tier.
    *
    * @param currency       address - the address of the accepted currency.
    */
    struct SubscriotionAPIParam {
        uint256 clubId;
        uint256 tierId;
        uint256 tierFee;
        address currency;
    }


    /** 
    * @notice The information of a subscription
    *
    * @param subscriptionId         uint256 - the uid of a subscription
    *
    * @param clubId                 uint256 - the uid of the subscripted club
    *
    * @param tierId                 uint256 - the uid of the subscripted tier
    *
    * @param subsriptor             address - the address of the subscriptor
    */
    struct Subscription {
        uint256 subscriptionId;
        uint256 clubId;
        uint256 tierId;
        address subscriptor; 
    }


    //  ==========  Event(s)    ==========


    /// @dev Emitted when a new Club is created
    event ClubCreated(address indexed clubOwner, Club club);

    /// @dev Emitted when a new tier is added
    event TierAdded(uint256 indexed tierId, address indexed clubOnwer, Tier newTier);

    /// @dev Emitted when a tier is updated
    event TierUpdated(uint256 indexed tierId, address indexed clubOwner, Tier updatedTier);

    /// @dev Emitted when a tier is deleted
    event TierDeleted(uint256 indexed tierId, address indexed clubOwner, Tier deletedTier);

    /// @dev Emitted when a subscription is made
    event SubscriptionMade(uint256 indexed subscriptionId, uint256 indexed tierId, address subscriptor, Subscription subscription);

    /// @dev Emitted when a subscription is canceled
    event SubscriptionCancel(uint256 indexed subscriptionId, uint256 indexed tierId, address subscriptor, Subscription subscription);

    

    //  ==========  Function(s)    ==========

    /** 
    * @notice Lets an account start a new Club
    *
    * @dev Start a new Club struct
    *
    * @param _currency  address - the address of the accepted currency
    */
    function startClub(address _currency) external;


    /** 
    * @notice Lets a Club's owner add a Tier
    *
    * @dev Create a new Tier struct and add it to corresponding Club
    *
    * @param _param     TierAPIParam - the parameter that governs the tier to be created.
    *                                  See struct `TierAPIParam` for more info.
    */
    function addTier(TierAPIParam memory _param) external;



    /** 
    * @notice Lets a Club's owner update a Tier
    *
    * @param _param     TierAPIParam - the parameter that governs the tier to be created.
    *                                  See struct `TierAPIParam` for more details.
    */
    function updateTier(TierAPIParam memory _param) external;


    /** 
    * @notice Lets a Club's owner delete a Tier
    */
    function deleteTier() external;


    /** 
    * @notice Lets an account subscribe to a Tier
    *
    * @param _param     SubscriotionAPIParam - the parameter that governs a subscription to be made.
    *                                          See struct `SubscriptionAPIParam` for more details.
    */
    function subsribe(SubscriotionAPIParam memory _param) external payable;


    /** 
    * @notice Lets a subscriber unsubscribe a Tier 
    *
    * @param _clubId     uint256 - the uid of the club holding the tier to be unsubscribed.
    *
    * @param _tierId     uint256 - the uid of the tier to be unsubscribed.
    */
    function unsubscribe(uint256 _clubId, uint256 _tierId) external;

}   

