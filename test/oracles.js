var Test = require("../config/testConfig.js");
const Web3 = require("web3");

var ether_port = "ws://127.0.0.1:8545";
var web3 = new Web3(new Web3.providers.WebsocketProvider(ether_port));

contract("Oracles", async (accounts) => {
  const TEST_ORACLES_COUNT = 20;
  var config;

 
  before("setup contract", async () => {
    config = await Test.Config(accounts);

    // Watch contract events
    const STATUS_CODE_UNKNOWN = 0;
    const STATUS_CODE_ON_TIME = 10;
    const STATUS_CODE_LATE_AIRLINE = 20;
    const STATUS_CODE_LATE_WEATHER = 30;
    const STATUS_CODE_LATE_TECHNICAL = 40;
    const STATUS_CODE_LATE_OTHER = 50;
  });

  afterEach(async function() {
    this.timeout(100000);
  });

  it("can register oracles", async () => {
    // ARRANGE
    let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();

    // ACT
    for (let a = 0; a < TEST_ORACLES_COUNT; a++) {
      let rand = Math.floor(Math.random() * 10);
      let account = web3.utils.toChecksumAddress(accounts[rand]);

      await config.flightSuretyApp.registerOracle({
        from: account,
        value: fee,
        gas: 500000,
      });
      let result = await config.flightSuretyApp.getMyIndexes.call({ gas: 50000, from: account });
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
    }
  });

  it("can request flight status", async () => {
    // ARRANGE
    let flight = "ND1309"; // Course number
    let timestamp = Math.floor(Date.now() / 1000);

    // Submit a request for oracles to get status information for a flight
    await config.flightSuretyApp.fetchFlightStatus(config.firstAirline, flight, timestamp);
    // ACT

    // Since the Index assigned to each test account is opaque by design
    // loop through all the accounts and for each account, all its Indexes (indices?)
    // and submit a response. The contract will reject a submission if it was
    // not requested so while sub-optimal, it's a good test of that feature
    for (let a = 1; a < TEST_ORACLES_COUNT; a++) {
      // Get oracle information

      let rand = Math.floor(Math.random() * 10);
      let account = web3.utils.toChecksumAddress(accounts[rand]);

      await config.flightSuretyApp.setOracleToRegistered.call({
        gas: 50000,
        from: account,
      });

      let oracleIndexes = await config.flightSuretyApp.getMyIndexes.call({
        gas: 50000,
        from: account,
      });
     
      for (let idx = 0; idx < 3; idx++) {
        try {
          // Submit a response...it will only be accepted if there is an Index match
          await config.flightSuretyApp.submitOracleResponse(
            oracleIndexes[idx],
            config.firstAirline,
            flight,
            timestamp,
            STATUS_CODE_ON_TIME,
            { from: accounts[a] }
          );
        } catch (e) {
          // Enable this when debugging
          console.log("\nError", idx, oracleIndexes[idx].toNumber(), flight, timestamp);
        }
      }
    }
  });
});
