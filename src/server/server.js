import FlightSuretyApp from "../../build/contracts/FlightSuretyApp.json";
import Config from "./config.json";
import Web3 from "web3";
import express from "express";

let config = Config["localhost"];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace("http", "ws")));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

flightSuretyApp.events.OracleRequest(
  {
    fromBlock: 0,
  },
  function(error, event) {
    if (error) console.log(error);
    console.log(event);
  }
);

let {
  submitOracleResponse,
  getMyIndexes,
  REGISTRATION_FEE,
  registerOracle,
} = flightSuretyApp.methods;

REGISTRATION_FEE()
  .call()
  .then(async (fee) => {
    for (let i = 0; i < 20; i++) {
      let rand = Math.floor(Math.random() * 10);
      let account = web3.utils.toChecksumAddress(web3.eth.accounts[rand]);
      registerOracle()
        .send({
          from: account,
          value: fee,
        })
        .then((resp) => console.log(resp))
        .catch((err) => console.log(err));
      getMyIndexes()
        .call({
          from: account,
        })
        .then((resp) => console.log(resp))
        .catch((err) => console.log(err));
    }

    flightSuretyApp.events.OracleRequest(
      {
        fromBlock: await web3.eth.getBlockNumber(),
      },
      (err, event) => subscribeToEvent(err, event)
    );

    // Subscribe to OracleRequest event and respond with all oracles available
    flightSuretyApp.events.OracleRequest(
      {
        fromBlock: await web3.eth.getBlockNumber(),
      },
      (err, event) => subscribeToEvent(err, event)
    );
  });

const subscribeToEvent = async (error, event) => {
  let { airline, flight, flightTimestamp, index } = event.returnValues;

  for (let i = 0; i < 20; i++) {
    let rand = Math.floor(Math.random() * 10);
    let account = web3.utils.toChecksumAddress(web3.eth.accounts[rand]);
    let indices = await getMyIndexes().call({
      from: account,
    });
    if (indices.includes(index)) {
      let selection = Math.floor(Math.random() * 4);

      await submitOracleResponse(airline, flight, flightTimestamp, selection).send({
        from: account,
      });
    }
  }
};

const app = express();
app.get("/api", (req, res) => {
  res.send({
    message: "An API for use with your Dapp!",
  });
});

export default app;
