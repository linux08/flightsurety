import FlightSuretyApp from "../../build/contracts/FlightSuretyApp.json";
import FlightSuretyData from "../../build/contracts/FlightSuretyData.json";
import Config from "./config.json";
import Web3 from "web3";

export default class Contract {
  constructor(network, callback) {
    let config = Config[network];
    this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
    this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
    this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.appAddress);
    this.initialize(callback);
    this.owner = null;
    this.airlines = [];
    this.passengers = [];
  }

  initialize(callback) {
    this.web3.eth.getAccounts((error, accts) => {
      this.owner = accts[0];

      let counter = 1;

      while (this.airlines.length < 5) {
        this.airlines.push(accts[counter++]);
      }

      while (this.passengers.length < 5) {
        this.passengers.push(accts[counter++]);
      }

      callback();
    });
  }

  isOperational(callback) {
    let self = this;
    self.flightSuretyApp.methods
      .requireIsOperational()
      .call({ gas: 50000, from: self.owner }, callback);
  }

  async buyInsurance(flight, callback) {
    let self = this;
    let payload = {
      airline: self.airlines[0],
      flight: flight,
      timestamp: Math.floor(Date.now() / 1000),
    };

    await self.flightSuretyData.methods.authoriseContract(this.owner);

    await self.flightSuretyData.methods.fund();
    self.flightSuretyData.methods
      .buyInsurance(payload.airline, payload.flight, payload.timestamp)
      .send(
        {
          from: this.owner,
        },
        (error, result) => {
          if (error) {
            console.log(error.message);
            alert("Transaction failed");
          }
          callback(error, payload);
          console.log("transaction hash", result);
          alert("Successfully purchase insurance");
        }
      );
  }
  fetchFlightStatus(flight, callback) {
    let self = this;
    let payload = {
      airline: self.airlines[0],
      flight: flight,
      timestamp: Math.floor(Date.now() / 1000),
    };
    self.flightSuretyApp.methods
      .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
      .send({ from: self.owner }, (error, result) => {
        if(error){
          return console.log(error.message)
        }
        callback(error, payload);
        console.log('result',result);
      });
  }
}
