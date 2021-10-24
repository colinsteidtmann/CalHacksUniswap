# Inflation adjusted employee salary using smart-contracts connected to Uniswap and Chainlink

## **Goal**:

Adjust employee salary for inflation using CPI. Pay employees automatically. Let the company store their assets in any token they want. Let employees get paid in any token they want.

## **Implementation**:

1. Company deposits money into a treasury using whatever currency they want the smart-contract to keep its assets in.
2. For each employee, the smart-contract keeps track of: the token they prefer to get paid in, the time-interval between their paychecks, their most recent salary, and the CPI at the time of their last paycheck.
3. A Chainlink keepers function triggers the smart-contract to pay an employee when the time since their last paycheck has elapsed their typical paycheck time-interval.
4. When an employee gets paid, the smart-contract uses a Chainlink api GET function to update the CPI.
5. Once triggered by the Chainlink keepers function and using the updated CPI, the smart-contract calls a Uniswap swapTokens function to swap between the company's preferred token to the employee's preferred token, and then pays the employee their inflation adjusted salary.

## **Future features**

- Let the company earn yields on their treasury tokens by letting them make loans or deposit into liquidity pools on Uniswap.
- Make a plugin that makes it easy for anyone to pay and get paid using whatever tokens they want. Eg. You go to the grocery store and the cashier wants USDC but all you want to carry is Ethereum. You should be able to open your app, click pay "20 USDC" (or whatever the cashier asks for), see a preview of the amount of ETH, press confirm, and the app automatically takes care of the swap and transfer in one transaction.

## **Important to note**

We ran out of time to fully implement these smart-contracts

## **Next steps**

Finish the smart-contracts. Write tests. Get audited. Deploy to mainnet.
