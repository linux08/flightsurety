var Test = require("../config/testConfig.js");
var BigNumber = require("bignumber.js");
const Config = require("../src/dapp/config.json");
const Web3 = require("web3");
const ethers = require("ethers");

this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));

let owner = null;

contract("Flight Surety Tests", async (accounts) => {
  var config;
  before("setup contract", async () => {
    config = await Test.Config(accounts);
    owner = config.owner;
    // console.log("config", config);
    await config.flightSuretyData.authoriseContract(config.flightSuretyApp.address);
  });

  afterEach(async function() {
    this.timeout(100000);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function() {
    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");
  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function() {
    // Ensure that access is denied for non-Contract Owner account
    let accessDenied = false;
    try {
      accessDenied = await config.flightSuretyData.setOperatingStatus(false, {
        gas: 50000,
        from: config.testAddresses[2],
      });
    } catch (e) {
      accessDenied = true;
    }
    assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function() {
    // Ensure that access is allowed for Contract Owner account
    let accessDenied = false;
    try {
      await config.flightSuretyData.setOperatingStatus(false);
    } catch (e) {
      accessDenied = true;
    }
    assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function() {
    await config.flightSuretyData.setOperatingStatus(false);

    let reverted = false;
    try {
      await config.flightSurety.setTestingMode(true);
    } catch (e) {
      reverted = true;
    }
    assert.equal(reverted, true, "Access not blocked for requireIsOperational");

    // Set it back for other tests to work
    await config.flightSuretyData.setOperatingStatus(true);
  });

  it("(airline) cannot register an Airline using registerAirline() if it is not funded", async () => {
    let newAirline = accounts[2];
    let result = false;

    // ACT
    try {
      await config.flightSuretyData.registerAirline(newAirline, "name7777", {
        from: config.firstAirline,
      });
      result = await config.flightSuretyData.isAirlineRegistered.call(newAirline);
      console.log("transaction hash", result);
    } catch (e) {
      console.log(e.message);
      result = false;
    }

    // ASSERT
    assert.equal(
      result,
      false,
      "Airline should not be able to register another airline if it hasn't provided funding"
    );
  });

  it("(airline) can register airline with funding", async () => {
    let newAirline = owner;
    let result = false;

    // ACT
    try {
      //authorize caller
      await config.flightSuretyData.authoriseContract(newAirline, { from: newAirline });

      await config.flightSuretyData.fund({ from: owner, value: 10 ** 19 });
      await config.flightSuretyApp.registerAirline(newAirline, "name7777", {
        from: owner,
      });

      result = await config.flightSuretyData.isAirlineRegistered.call(newAirline);
    } catch (e) {
      console.log(e.message);
      result = false;
    }

    // ASSERT
    assert.equal(result, true, "Airline should be able to register with enough funding");
  });

  it.only("(airline) can buy insurance", async () => {
    let result = false;

    // ACT
    try {
      //authorize caller
      await config.flightSuretyData.authoriseContract(owner, { from: owner });

      await config.flightSuretyData.fund({ from: owner, value: 10 ** 19 });
      let res = await config.flightSuretyData.buyInsurance(
        owner,
        "name7777",
        Math.floor(Date.now() / 1000),
        // {
        //   // gas: 50000,
        //   // value:  10 ** 19 ,
        //   // from: owner, //config.firstAirline,
        // }
      );

      console.log("res", res);

      // result = await config.flightSuretyData.isAirlineRegistered.call(newAirline);
    } catch (e) {
      console.log(e.message);
      result = false;
    }

    // ASSERT
    assert.equal(result, true, "Airline should be able to register with enough funding");
  });
});
