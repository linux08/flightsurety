// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract

    struct Airline {
        bool isRegistered;
        address airlineOwner;
        string name;
        address[] voters;
    }

    uint256 public registeredAirlineCount = 0;

    uint256 public constant INSURANCE_POLICY_FEE = 1 ether;
    uint256 public constant AIRLINE_FUNDING_FEE = 10 ether;

    mapping(address => Airline) private airlines; // mapping for storing airlines
    mapping(address => uint256) public funds; // mapping for storing funds
    mapping(address => bool) authorizedContracts; // mapping for storing authorized contract

    struct Passenger {
        address passengerAddress;
        uint256[] insuredFlights;
        uint256 balance;
    }
    address[] public passengersAddreses;
    mapping(address => Passenger) private passengers; // mapping for storing airlines

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     * The deploying account becomes contractOwner
     * Register first airline on contract deployment
     */
    constructor() {
        contractOwner = msg.sender;
        address airline = msg.sender;
        airlines[airline].isRegistered = true;
        airlines[airline].airlineOwner = msg.sender;
        airlines[airline].name = "First airline";
        registeredAirlineCount += 1;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

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
        require(funds[airline] >= AIRLINE_FUNDING_FEE, "Insufficient fund");
        _;
    }

    modifier isCallerAuthorised() {
        require(authorizedContracts[msg.sender], "Caller is not authorised");
        _;
    }

    modifier ensurePassengerHasFunds() {
        require(
            (address(this).balance > passengers[payable(msg.sender)].balance),
            "Not enough funds"
        );
        _;
    }

    modifier checkIfPassengerHasAbove1ETH() {
        require(msg.value >= INSURANCE_POLICY_FEE, "Insufficient fund");
        _;
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsOperational() {
        // Modify to call data contract's status
        require(true, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
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
     * @dev Get authorization  status of contract
     *
     * @return A bool that is the current operating status
     */

    function isAuthorised(address contractAddress) public view returns (bool) {
        return authorizedContracts[contractAddress];
    }

     function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
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
                airlines[airline].voters.length >= registeredAirlineCount.div(2)
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
    function buy(
        address passengerAddress,
        string memory flight,
        uint256 timestamp
    ) external payable checkIfPassengerHasAbove1ETH {
        bytes32 flightKey = getFlightKey(passengerAddress, flight, timestamp);
        //New passenger

        //Existing passenger
        if (
            passengers[passengerAddress].insuredFlights[uint256(flightKey)] == 0
        ) {
            passengers[passengerAddress].insuredFlights[
                uint256(flightKey)
            ] = msg.value;
        } else {
            passengersAddreses.push(passengerAddress);
            passengers[passengerAddress].passengerAddress = passengerAddress;
            passengers[passengerAddress].insuredFlights[
                uint256(flightKey)
            ] = msg.value;
            passengers[passengerAddress].balance = 0;
        }
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(
        string calldata flight,
        uint256 timestamp,
        address airline
    ) external requireIsOperational isCallerAuthorised {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);

        for (uint256 i = 0; i <= passengersAddreses.length; i++) {
            address pAddress = passengersAddreses[i];
            passengers[pAddress].insuredFlights[uint256(flightKey)] = 0;
        }
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay()
        external
        payable
        requireIsOperational
        isCallerAuthorised
        ensurePassengerHasFunds
    {
        uint256 passengerCredit = passengers[msg.sender].balance;
        passengers[msg.sender].balance = 0;
        payable(msg.sender).transfer(passengerCredit);
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund()
        public
        payable
        requireIsOperational
        isCallerAuthorised
        checkIfAirlineHasFunds(msg.sender)
    {
        funds[msg.sender] = funds[msg.sender].add(msg.value);
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
