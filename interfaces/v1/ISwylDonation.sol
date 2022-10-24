/*
    @dev: Logan (Nam) Nguyen
    @Course: SUNY Oswego - CSC 495 - Capstone
    @Instructor: Professor Bastian Tenbergen
    @Version: 1.0
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwylDonation {

    //  ==========  Enumerables    ==========

    /// @notice The donation can either be one-time or monthly.
    /// @notice Monthly is v2.0 features
    enum DonationType {
        OneTime,
        Monthly
    }


    //  ==========  Struct(s)    ==========

    /**
    * @notice The information of a Donation
    *
    * @param donationId         uint256 - The unique id of the donation.
    *
    * @param donator            address - The address of the sender who makes the donation.
    *
    * @param donatee            address - The address of the recipient who receives the donation.
    *
    * @param donationAmount     uint256 - The total amount of the donation.
    *
    * @param currency           address - The address of the currency in which `donator` makes the donation.
    *                                     Must match the currency donatee accepts.
    *
    * @param date               uint256 - A unix timestamp to record the date the donation is created
    *
    * @param donationType       DonationType - The type of the donation (one-time or monthly).
    */
    struct Donation {
        uint256 donationId;
        address donator;
        address donatee;
        uint256 donationAmount;
        address currency;
        uint256 date;
        DonationType donationType;
    }


    /**
    * @notice For use in `makeDonation()` as a parameter type.
    *
    * @param donationAmount         uint256 - The amount the donator wish to donate.
    *
    * @param donatee                address - The address that receives the donation.
    *
    * @param currency               address - The address of the currency to be used.
    *
    * @param donationType           DonationType - Monthly or one-time.
    */
    struct MakeDonationParam {
        uint256 donationAmount;
        address donatee;
        address currency;
        DonationType donationType;
    }


    /**
    * @notice For use in `updateDonation()` as a parameter type.
    *
    * @param donationId             uint256 - The uid of the targetDonation to be updated.
    *
    * @param donationAmount         uint256 - The amount the donator wish to donate.
    *
    * @notice v2.0 features
    */
    struct UpdateDonationParam {
        uint256 donationId;
        uint256 donationAmount;
    }



    //  ==========  Event(s)    ==========

    /// @dev Emitted when a new donation is made.
    event DonationMade(uint256 indexed donationId, address indexed donator, address donatee, Donation donation, DonationType donationType);

    /// @dev Emiited when a monthly-donation is updated.
    event DonationUpdated(uint256 indexed donationId, address indexed donator, address donatee, Donation donation);

    /// @dev Emitted when a monthly-donation is canceled.
    event DonationCanceled(uint256 indexed donationId, address indexed donator, address donatee);

    
    
    //  ==========  Function(s)    ==========
    
    /**
    * @notice Lets an account make a donation and send the donation amount to a receiver.
    * 
    * @param _param MakeDonationParam - The parameter that governs the donation to be created.
    *                                   See struct MakeDonationParam for more info.
    */
    function makeDonation(MakeDonationParam memory _param) external payable;


    /**
    * @notice Only for monthly donation type.
    *
    * @notice Lets a donator make an update to the monthly donation created by them.
    *
    * @param _param UpdatedDonationParam - The parameter that governs a monthly donation to be updated.
    *                                      See struct UpdateDonationParam for more info.
    *
    * @notice v2.0 features
    */
    function updateDonation(UpdateDonationParam memory _param) external;


    /**
    * @notice Lets a donator cancel the monthly donation created by them.
    *
    * @param _donationId uint256 - the uid of the target donation to be deleted.
    *
    * * @notice v2.0 features
    */
    function cancelDonation(uint256 _donationId) external;

}