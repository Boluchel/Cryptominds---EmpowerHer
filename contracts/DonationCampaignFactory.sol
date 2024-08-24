// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./DonationCampaign.sol";

contract DonationFactory {
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

    // State variables
    uint32 id;
    DonationCampaign.CampaignDetails[] allCampaigns;
    mapping(address => DonationCampaign.CampaignDetails[]) campaignsByAddress;
    mapping(uint256 => DonationCampaign.CampaignDetails) campaignByID;
    mapping(uint256 => address) campaignAddress;


      /**
     * @dev Emitted when campaign is created
     */
    event createdCampaign(
        string indexed campaignName,
        uint256 indexed campaignTargetAmount,
        uint256 indexed campaignCreatedTime
    );

    function createDonationCampaign(
        string memory _campaignName,
        string memory _campaignDescription,
        string memory _campaignImage,
        uint256 _campaignStartTime,
        uint256 _campaignEndTime,
        uint256 _campaignTargetAmount
    ) external {
        DonationCampaign newCampaign = new DonationCampaign(
            msg.sender,
            _campaignName,
            _campaignDescription,
            _campaignImage,
            _campaignStartTime,
            _campaignEndTime,
            _campaignTargetAmount,
            ++id
        );

        campaignAddress[id] = address(newCampaign);

        campaignByID[id] = newCampaign.getCampaignDetails();

        campaignsByAddress[msg.sender].push(newCampaign.getCampaignDetails());

        allCampaigns.push(newCampaign.getCampaignDetails());

        emit createdCampaign(_campaignName, _campaignTargetAmount, _campaignEndTime);

    }

    /**
     * @notice Returns all the campaigns that have been created by any user.
     * @dev The result is returned as an array of CampaignDetails structs.
     * @return AllCampaignDetails An array containing details about all active and ended campaigns.
     */
    function getAllCampaignDetails()
        external
        view
        returns (DonationCampaign.CampaignDetails[] memory)
    {
        return allCampaigns;
    }

    /**
     * @notice Returns all the campaigns that a specific user has created.
     * @dev The result is returned as an array of CampaignDetails structs.
     * @param  _addr The address of the user whose campaigns are to be retrieved.
     * @return UserCampaignDetails An array containing details about all active and ended campaigns by the user.
     */
    function getCampaignByAddress(address _addr)
        external
        view
        returns (DonationCampaign.CampaignDetails[] memory)
    {
        return campaignsByAddress[_addr];
    }

    /**
     * @notice Returns the details of a specific campaign.
     * @dev The result is returned as a CampaignDetails struct.
     * @param  _id The id of the campaign whose details are to be retrieved.
     * @return SpecificCampaignDetails Details about the specified campaign.
     */
    function getCampaignByID(uint256 _id)
        external
        view
        returns (DonationCampaign.CampaignDetails memory)
    {
        return campaignByID[_id];
    }

    function getCampaignAddress(uint256 _id)
        external
        view
        returns (address)
    {
        return campaignAddress[_id];
    }

    /**
     * @notice Returns the total amount of fees received by this contract in wei.
     * @dev The result is returned as a uint256.
     * @return TotalFeesReceived The total amount of fees received by this contract in wei.
     */
    function checkTotalFeesGotten() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    fallback() external payable {}
}
