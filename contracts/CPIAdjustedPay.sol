// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract CPIAdjustedPay is ChainlinkClient, KeeperCompatibleInterface {
    using Chainlink for Chainlink.Request;

    /// ============ Contract Storage ============
    uint256 public treasuryBalance; /// Denominated in companyToken. Example: 1030000000000000000 WEI
    uint256 public latestInflationRate; ///  CPI measured in USD with 18 decimals. Example: 274310000000000000000.
    uint256 public employeesToPayLength; /// Size of "employeesToPay" array.
    uint256 public fee = 0.1 * 10**18; /// 0.1 LINK

    address public companyToken; /// Token address company holds their assets in
    address[] public employees; /// Array of employee wallet address
    address[] public employeesToPay; /// Size always equals number of employees. Updates every time performUpkeep is called.
    address public oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8; /// Chainlink Oracle.

    bytes32 public jobId = "d5270d1c311941d0b08bead21fea7747"; /// Chainlink Kovan GET -> Uint256 jobID

    mapping(address => address) public employeeTokens; /// address employee => address ERC20Token
    mapping(address => uint256) public employeePayIntervals; /// address employee => uint256 payIntervalSeconds
    mapping(address => uint256[]) public employeeRecentPayData; /// address employee => [uint salary, uint lastPayTimestamp, uint lastPayCPI]

    /// ============ Calculations ============
    ///  @dev Return (old-salary * new-cpi)/old-cpi
    function getEmployeeAdjustedSalaryInDollars(address employee)
        public
        returns (uint256 adjustedSalary)
    {
        uint256[] memory data = employeeRecentPayData[employee];
        uint256 oldSalary = data[0]; /// example 300000000000000000 WEI
        uint256 oldCPI = data[2]; /// example 274310000000000000000 USD
        uint256 newSalary = (oldSalary * latestInflationRate) / oldCPI;
        return newSalary;
    }

    /**
      @dev
      1. For each employee: check if (current block timestamp - last employee time stamp) >  payInterval
      2. return performData — a list of employee addresses that need to be paid and an amount in dollars to pay each employee
    */
    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 numberEmployeesToPay; /// aka tempEmployeesToPay array length
        address[] memory tempEmployeesToPay = new address[](employees.length);

        for (uint256 i = 0; i < employees.length; i++) {
            address employee = employees[i];
            uint256 employeePayInterval = employeePayIntervals[employee];
            uint256 lastPaidTimestamp = employeeRecentPayData[employee][1];

            if ((block.timestamp - lastPaidTimestamp) > employeePayInterval) {
                upkeepNeeded = true;
                tempEmployeesToPay[numberEmployeesToPay] = employee;
                numberEmployeesToPay++;
            }
        }

        return (
            upkeepNeeded,
            abi.encode(tempEmployeesToPay, numberEmployeesToPay)
        );
    }

    /// @dev Do Chainlink API GET request
    function requestInflationRate() public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillInflationRateRequest.selector
        );

        /// Set the URL to perform the GET request on
        request.add(
            "get",
            "https://api.bls.gov/publicAPI/v2/timeseries/data/CUUR0000SA0"
        );
        request.add("path", "Results.series.0.data.0.value");

        /// Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10**18;
        request.addInt("times", timesAmount);

        /// Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /// ============ State Changing ============
    /**
      @dev
      1. use list of employee addresses passed by checkUpkeep to pay the correct employees. 
      2. call requestInflationRate to trigger paying correct employees
    */
    function performUpkeep(bytes calldata performData) external override {
        (employeesToPay, employeesToPayLength) = abi.decode(
            performData,
            (address[], uint256)
        );
        requestInflationRate();
    }

    /// @dev Set contract inlfation rate, pay employees and update their pay data.
    function fulfillInflationRateRequest(
        bytes32 requestId,
        uint256 inflationRate
    ) public {
        latestInflationRate = inflationRate;
        for (uint256 i = 0; i < employeesToPayLength; i++) {
            address employee = employeesToPay[i];
            /// pay employee i
        }
    }

    /**
    @dev
    1. call TokenSwap contract's convert method
    2. send converted tokens to employee
    */
    function payEmployee(address employeeAddress)
        public
        returns (bool success)
    {}

    /// @dev transfer(companyTokenAmt) on IERC20(comppanyToken). Update company treasure
    function deposit(uint256 companyTokenAmt) public {}

    function changeCompanyToken(address newToken) public {
        companyToken = newToken;
    }

    function changeEmployeeToken(address employee, address newToken) public {
        employeeTokens[employee] = newToken;
    }
}
