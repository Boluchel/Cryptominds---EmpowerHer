// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// errors
error NOT_AUTHORIZED();
error CAMPAIGN_ENDED();
error AMOUNT_CANT_BE_0();
error INSUFICIENT_BALANCE();
error CAMPAIGN_NOT_STARTED();
error CAMPAIGN_TARGET_MET();

/**
 * @dev DonationCampaign is a contract that represents a campaingn donation
 */
contract DonationCampaign is ReentrancyGuard{
    /**
     * @dev Struct representing the details of a campaign
     */
    struct CampaignDetails {
        uint32 campaignID;
        address campaignOwner;
        string campaignName;
        string campaignDescription;
        string campaignImage;
        uint256 campaignCreatedTime;
        uint256 campaignStartTime;
        uint256 campaignEndTime;
        uint256 campaignTargetAmount;
        uint256 amountCampaignReceived;
        uint256 campaignBalance;
        address[] donors;
        bool isCampaignEnded;
    }

    /**
     * @dev Emitted when campaign is created
     */
    event createdCampaign(
        string indexed campaignName,
        uint256 indexed campaignTargetAmount,
        uint256 indexed campaignCreatedTime
    );

    /**
     * @dev Emitted when campaign is updated
     */
    event updatedCampaign(
        uint256 indexed campaignTargetAmount,
        uint256 indexed campaignEndTime
    );

    /**
     * @dev Emitted when a user donates to the campaign
     */
    event campaignDonated(
        uint256 indexed amountDonated,
        uint256 indexed totalAmountReceived
    );

    /**
     * @dev Emitted when a user withdraws from the campaign
     */
    event campaignWithdrawal(
        uint256 indexed amountWithdrawn,
        uint256 indexed campaignBalance
    );

    /**
     * @dev Emitted when a campaign is ended
     */
    event campaignEnded(
        uint256 indexed totalAmountReceived,
        uint256 indexed campaignTargetAmount,
        uint256 indexed campaignEndTime
    );

    // State Variables
    CampaignDetails public campaignDetails;
    address factoryAddress;

    /// @notice Constructor for the DonationCampaign contract.
    /// @dev This function is used to initialize the contract when it is deployed.
    /// @param _campaignOwner The address of the campaign owner.
    /// @param _campaignName The name of the campaign.
    /// @param _campaignDescription A description of the campaign.
    /// @param _campaignImage An image or logo for the campaign.
    /// @param _campaignStartTime The start time of the campaign in Unix timestamp format.
    /// @param _campaignEndTime The end time of the campaign in Unix timestamp format.
    /// @param _campaignTargetAmount The target amount that the campaign is aiming for.
    /// @param _campaignID A unique identifier for the campaign.
    constructor(
        address _campaignOwner,
        string memory _campaignName,
        string memory _campaignDescription,
        string memory _campaignImage,
        uint256 _campaignStartTime,
        uint256 _campaignEndTime,
        uint256 _campaignTargetAmount,
        uint32 _campaignID
    ) {
        factoryAddress = msg.sender;
        campaignDetails = CampaignDetails({
        campaignID: _campaignID,
        campaignOwner: _campaignOwner,
        campaignName: _campaignName,
        campaignDescription: _campaignDescription,
        campaignImage: _campaignImage,
        campaignCreatedTime: block.timestamp,
        campaignStartTime: _campaignStartTime,
        campaignEndTime: _campaignEndTime,
        campaignTargetAmount: _campaignTargetAmount,
        amountCampaignReceived: 0,
        campaignBalance: 0,
        donors:new address[](0),
        isCampaignEnded: false
        });

        emit createdCampaign(_campaignName, _campaignTargetAmount, block.timestamp);
    }

    /// @notice Restricts access to only the campaign owner.
    /// @dev This function checks if the sender of the transaction is the campaign owner. If not, it reverts with an error message indicating that the user is not authorized.
    function onlyCampaignOwner() private view {
        
        if (msg.sender != campaignDetails.campaignOwner) {revert NOT_AUTHORIZED();}
        
    }

    /// @notice Updates campaign details.
    /// @dev This function allows the campaign owner to update the end time and target amount of the campaign. 
    /// If called before the start time, it reverts with an error message indicating that the campaign has not started yet.
    /// @param _campaignEndTime The new end time for the campaign in Unix timestamp format.
    /// @param _campaignTargetAmount The new target amount for the campaign.
    function updateCampaign( uint _campaignEndTime, uint _campaignTargetAmount ) external {

        onlyCampaignOwner();

        if (block.timestamp < campaignDetails.campaignStartTime){revert CAMPAIGN_NOT_STARTED(); }
        
        campaignDetails.campaignTargetAmount = _campaignTargetAmount;
        
        campaignDetails.campaignEndTime = _campaignEndTime;

        emit updatedCampaign(_campaignTargetAmount, _campaignEndTime);

    }

    /// @notice Donates funds to the campaign.
    /// @dev This function allows users to donate Ether to the campaign by sending it as a transaction. 
    /// It checks if the amount sent is not zero, if the campaign has not ended and if it hasn't started yet.
     function donateToCampaign() external payable{

        if (msg.value == 0){revert AMOUNT_CANT_BE_0();}

        if (block.timestamp < campaignDetails.campaignStartTime){revert CAMPAIGN_NOT_STARTED();}

        if (block.timestamp > campaignDetails.campaignEndTime){revert CAMPAIGN_ENDED();}

        if (campaignDetails.isCampaignEnded){revert CAMPAIGN_TARGET_MET();}

        uint _newBalance = campaignDetails.campaignBalance + msg.value;

        uint _newTotalAmountReceived = campaignDetails.amountCampaignReceived + msg.value;

        campaignDetails.campaignBalance = _newBalance;

        campaignDetails.amountCampaignReceived = _newTotalAmountReceived;

        campaignDetails.donors.push(msg.sender);

        if (_newTotalAmountReceived >= campaignDetails.campaignTargetAmount){ campaignDetails.isCampaignEnded = true;}

        emit campaignDonated(msg.value, _newTotalAmountReceived);

    }

    /// @notice Withdraws funds from the campaign.
    /// @dev This function allows the campaign owner to withdraw Ether from the campaign. 
    /// It calculates a withdrawal fee and subtracts it from the amount withdrawn, sending both amounts (withdrawal fee and actual balance) to the factory contract and the sender respectively. 
    /// The function is reentrant safe.
    /// @param _amount The amount of Ether to be withdrawn by the owner.
    function withdrawFromCampaign(uint _amount) external nonReentrant {

        onlyCampaignOwner();

        if (block.timestamp < campaignDetails.campaignStartTime){revert CAMPAIGN_NOT_STARTED();}

        if (_amount > campaignDetails.campaignBalance){ revert INSUFICIENT_BALANCE(); }

        uint _newCampaignBalance = campaignDetails.campaignBalance - _amount;

        campaignDetails.campaignBalance = _newCampaignBalance;

        uint _withdrawalFee = _amount * 2 / 100;

        uint _withdrawBalance = _amount - _withdrawalFee;

        payable(factoryAddress).transfer(_withdrawalFee);

        payable(msg.sender).transfer(_withdrawBalance);

        emit campaignWithdrawal(_amount, _newCampaignBalance);

    }

    /// @notice Ends the campaign.
    /// @dev This function allows the campaign owner to end the campaign and record the time it ended. 
    /// It sets the isCampaignEnded flag to true.
    function endCampaign() external  {

        onlyCampaignOwner();

        campaignDetails.isCampaignEnded = true;

        campaignDetails.campaignEndTime = block.timestamp;

        emit campaignEnded(campaignDetails.amountCampaignReceived, campaignDetails.campaignTargetAmount, block.timestamp);

     }


    /// @notice Retrieves the details of a campaign.
    /// @dev This function returns all the details related to a campaign.
    /// @return The struct containing all the details about the campaign.

      function getCampaignDetails() external view returns(CampaignDetails memory) {
        return  campaignDetails;
     }

    /// @notice Fallback function that allows users to send Ether directly to this contract.
    /// @dev This function is triggered when a user sends Ether directly to this contract, without calling one of the defined functions. 
    /// The Ether is not used in this contract. Instead, it's kept by the contract and can be withdrawn later by the owner.
    receive() external payable {}

    fallback() external payable {}

}
