// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

contract TokenSwap {
    /// ============ Constants ============
    ISwapRouter public constant uniswapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoter public constant quoter =
        IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    uint256 MAX_INT = 2**256 - 1;

    /// ============ Functions ============
    constructor() public {}

    /** 
    @notice
    swaps company treasury tokens into US-dollar-equivalent amount of desired employee tokens
    e.g. "converts company ETH into 10 dollars worth of DOGE"
    */
    function convertCompanyTokensToEmployeeTokens(
        address companyToken,
        address employeeToken,
        uint256 employeeAdjustedSalaryInDollars
    ) external payable returns (bool) {
        /**
        valid test inputs on Ropsten:
        companyToken = 0x31f42841c2db5173425b5223809cf3a38fede360    (DAI addr)
        employeeToken = 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984   (UNI addr)
        employeeAdjustedSalaryInDollars = 10
        */
        require(
            employeeAdjustedSalaryInDollars > 0,
            "Must pass non 0 salary amt"
        );

        uint256 deadline = block.timestamp + 15; /// using 'now' for convenience, for mainnet pass deadline from frontend
        address tokenIn = companyToken;
        address tokenOut = employeeToken;
        uint24 fee = 3000; /// 0.30% (medium-risk) fee tier
        address recipient = msg.sender;
        uint256 amountOut = getEstimatedEmployeeTokenAmt(
            employeeToken,
            employeeAdjustedSalaryInDollars
        );
        uint256 amountInMaximum = MAX_INT;
        uint160 sqrtPriceLimitX96 = 0;

        /// swap as many CompanyTokens required to get the desired amount of EmployeeTokens
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                recipient,
                deadline,
                amountOut,
                amountInMaximum,
                sqrtPriceLimitX96
            );

        uint256 amountIn = uniswapRouter.exactOutputSingle(params);

        return (amountIn < amountInMaximum && amountIn > 0) ? true : false;
    }

    /**
    @dev
    gets a quote for the expected quantity of EmployeeTokens based on the given employee salary in dollars
    replaceable by a chainlink <EmployeeToken>/USDC price feed quote
    */
    function getEstimatedEmployeeTokenAmt(
        address employeeToken,
        uint256 employeeAdjustedSalaryInDollars
    ) public payable returns (uint256) {
        address tokenIn = employeeToken;
        address tokenOut = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; /// this is the checksummed USDC addr on Ropsten testnet
        uint24 fee = 3000; /// 0.30% (medium-risk) fee tier
        uint160 sqrtPriceLimitX96 = 0;

        /// get a quote denominated in EmployeeToken
        return
            quoter.quoteExactOutputSingle(
                tokenIn,
                tokenOut,
                fee,
                employeeAdjustedSalaryInDollars,
                sqrtPriceLimitX96
            );
    }
}
