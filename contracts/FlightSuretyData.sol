// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./FlightSuretyApp.sol";

contract FlightSuretyData is FlightSuretyApp {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    struct Airline {
        bool isRegistered;
        address airlineOwner;
        string name;
        address[] voters;
    }

    uint256 public registeredAirlineCount = 0;

    uint256 public constant INSURANCE_POLICY_FEE = 1 ether;
    uint256 public constant AIRLINE_FUNDING_FEE = 10 ether;

    mapping(address => Airline) public airlines; // mapping for storing airlines
    mapping(address => uint256) public funds; // mapping for storing funds
    mapping(address => bool) authorizedContracts; // mapping for storing authorized contract

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     * The deploying account becomes contractOwner
     * Register first airline on contract deployment
     */
    constructor(address airline) {
        authorizeCaller(msg.sender);
        contractOwner = msg.sender;
        airlines[airline].isRegistered = true;
        registeredAirlineCount += 1;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier allowOnlyRegisteredAirline(address airline) {
        require(
            airlines[airline].isRegistered == false,
            "Airline already registered"
        );
        _;
    }

    modifier allowOnlyUnRegisteredAirline(address airline) {
        require(
            airlines[airline].isRegistered == true,
            "Airline already registered"
        );
        _;
    }

    modifier checkIfAirlineHasFunds(address airline) {
        require(funds[address] >= AIRLINE_FUNDING_FEE, "Insufficient fund");
        _;
    }

    modifier isCallerAuthorised() {
        require(authorizedContracts[msg.sender], "Caller is not authorised");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev function to authorize contract
     *
     */
    function authoriseContract(address contractAddress)
        external
        requireContractOwner
    {
        authorizedContracts[contractAddress] = true;
    }

    /**
     * @dev function to authorize contract
     *
     */
    function unAuthorizeContract(address contractAddress)
        external
        requireContractOwner
    {
        authorizedContracts[contractAddress] = false;
    }

    /**
     * @dev function to authorize caller
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Get authorization  status of contract
     *
     * @return A bool that is the current operating status
     */

    function isAuthorised(address contractAddress) public view returns (bool) {
        return authorizedContracts[contractAddress];
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(address airline, string memory name)
        external
        requireIsOperational
        allowOnlyUnRegisteredAirline(airline)
        isCallerAuthorised
        checkIfAirlineHasFunds(airline)
    {

        if (registeredAirlineCount >= 4) {
            // Check to ensure that an airline doesn't vote multiple times
            for (uint256 i = 0; i < airlines[airline].voters.length; i++) {
                require(
                    airlines[airline].voters[i] != msg.sender,
                    "Current Airline already approved"
                );
            }

            airlines[airline].voters.push(msg.sender);
            if (
                // Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
                airlines[airline].approvals.length >=
                registeredAirlineCount.div(2)
            ) {
                airlines[airline].isRegistered = true;
            }
        } else {
            airlines[airline].isRegistered = true;
            airlines[airline].name = name;
            registeredAirlineCount = registeredAirlineCount.add(1);
        }
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy() external payable {}

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees() external pure {}

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay() external pure {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund() public payable {}

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    fallback() external payable {
        fund();
    }

    receive() external payable {
        // custom function code
    }
}
