import DOM from "./dom";
import Contract from "./contract";
import "./flightsurety.css";

(async () => {
  let result = null;

  let contract = new Contract("localhost", () => {
    try {
      // Read transaction
      contract.isOperational((error, result) => {
        console.log(error, result);
        display("Operational Status", "Check if contract is operational", [
          { label: "Operational Status", error: error, value: result },
        ]);
      });

      // User-submitted transaction
      DOM.elid("submit-oracle").addEventListener("click", () => {
        let flight = DOM.elid("flight-number").value;
        // Write transaction
        contract.fetchFlightStatus(flight, (error, result) => {
          display("Oracles", "Trigger oracles", [
            {
              label: "Fetch Flight Status",
              error: error,
              value: result.flight + " " + result.timestamp,
            },
          ]);
        });
      });

      // purchase insurance
      DOM.elid("purchase-insurance").addEventListener("click", () => {
        let flight = DOM.elid("flight-insnumber").value;
        // Write transaction
        contract.buyInsurance(flight, (error, result) => {
          display("Buy", "Buy Insurance", [
            {
              label: "Buy insurance",
              error: error,
              value: result.flight + " " + result.timestamp,
            },
          ]);
        });
      });

      // purchase insurance
      DOM.elid("flight-status-update").addEventListener("click", () => {
        let flight = DOM.elid("flight-upnumber").value;
        // Write transaction
        contract.buyInsurance(flight, (error, result) => {
          display("Oracles", "flight update", [
            {
              label: "Flight update",
              error: error,
              value: result.flight + " " + result.timestamp,
            },
          ]);
        });
      });
    } catch (err) {
      console.log(err);
    }
  });
})();

function display(title, description, results) {
  let displayDiv = DOM.elid("display-wrapper");
  let section = DOM.section();
  section.appendChild(DOM.h2(title));
  section.appendChild(DOM.h5(description));
  results.map((result) => {
    let row = section.appendChild(DOM.div({ className: "row" }));
    row.appendChild(DOM.div({ className: "col-sm-4 field" }, result.label));
    row.appendChild(
      DOM.div(
        { className: "col-sm-8 field-value" },
        result.error ? String(result.error) : String(result.value)
      )
    );
    section.appendChild(row);
  });
  displayDiv.append(section);
}
