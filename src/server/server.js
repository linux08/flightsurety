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

// Spin up 20+ Oracles at initialization
let fee = await REGISTRATION_FEE().call();
for (let i = 0; a < 20; a++) {
  await registerOracle().send({
    from: web3.eth.accounts[i],
    value: fee,
  });
   await getMyIndexes().call({
    from: web3.eth.accounts[i],
  });
}

flightSuretyApp.events.OracleRequest(
  {
    fromBlock: await web3.eth.getBlockNumber(),
  },
  (err, event) => submitResponse(err, event)
);

// Subscribe to OracleRequest event and respond with all oracles available
flightSuretyApp.events.OracleRequest(
  {
    fromBlock: await web3.eth.getBlockNumber(),
  },
  (err, event) => subscribeToEvent(err, event)
);

const subscribeToEvent = async (error, event) => {
  let { airline, flight, flightTimestamp, index } = event.returnValues;

  for (let a = 0; a < N_ORACLES; a++) {
    let indices = await getMyIndexes().call({
      from: accounts[a],
    });
    if (indices.includes(index)) {
      let selection = Math.random() * 4;

      await submitOracleResponse(airline, flight, flightTimestamp, selection).send({
        from: accounts[i],
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
