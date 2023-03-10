// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

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
        uint256 balance;
        mapping(bytes32 => uint256) insuredFlights;
    }
    address[] public passengersAddreses;
    mapping(address => Passenger) private passengers; // mapping for storing airlines

    uint256 bankBalance = 0;
    bool private operational = true;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event InsuranceBought(address airline);

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
        address payable towner = payable(msg.sender);
        require(
            (address(this).balance > passengers[towner].balance),
            "Not enough funds"
        );
        _;
    }

    modifier checkIfPassengerHasAbove1ETH(address airline) {
        require(funds[airline] >= INSURANCE_POLICY_FEE, "Insufficient fund");
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
     * @dev To check whether the specific airline is registered
     */
    function isAirlineRegistered(address airline) external view returns (bool) {
        return airlines[airline].isRegistered;
    }

    /**
     * @dev function to authorize caller
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    function setOperatingStatus(bool status) external requireContractOwner {
        operational = status;
    }

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
     *           // checkIfAirlineHasFunds(airline)
     */

    function registerAirline(address airline, string memory name)
        external
        requireIsOperational
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
    function buyInsurance(
        address passengerAddress,
        string memory flight,
        uint256 timestamp
    ) external payable checkIfPassengerHasAbove1ETH(passengerAddress) {
        bytes32 flightKey = getFlightKey(passengerAddress, flight, timestamp);
        // uint256 passengerBalance = passengers[passengerAddress].balance;

        if (passengers[passengerAddress].insuredFlights[flightKey] == 0) {
            passengers[passengerAddress].insuredFlights[
                flightKey
            ] = INSURANCE_POLICY_FEE;

            // passengers[passengerAddress].balance =
            //     passengerBalance -
            //     INSURANCE_POLICY_FEE;
            bankBalance = bankBalance.add(INSURANCE_POLICY_FEE);
        } else {
            passengersAddreses.push(passengerAddress);
            passengers[passengerAddress].passengerAddress = passengerAddress;
            passengers[passengerAddress].insuredFlights[
                flightKey
            ] = INSURANCE_POLICY_FEE;
            // passengers[passengerAddress].balance =
            //     passengerBalance -
            //     INSURANCE_POLICY_FEE;
            bankBalance = bankBalance.add(INSURANCE_POLICY_FEE);
        }

        emit InsuranceBought(passengerAddress);
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
            passengers[pAddress].insuredFlights[flightKey] = 0;
            uint256 HALF_INSURANCE_POLICY_FEE = 1 ether;
            bankBalance = bankBalance.sub(HALF_INSURANCE_POLICY_FEE);
            passengers[pAddress].balance = passengers[pAddress].balance.add(
                INSURANCE_POLICY_FEE.add(INSURANCE_POLICY_FEE.div(2))
            );
        }
    }

    /**
     *  @dev Payout
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
        address payable towner = payable(msg.sender);
        towner.transfer(passengerCredit);
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund() public payable requireIsOperational isCallerAuthorised {
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
