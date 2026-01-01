// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPancakeRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IFlashLoanProvider {
    function flashLoan(
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

contract Frontrunner is Ownable, ReentrancyGuard {
    IPancakeRouter public constant PANCAKE_ROUTER = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeFactory public constant PANCAKE_FACTORY = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IFlashLoanProvider public constant FLASH_LOAN_PROVIDER = IFlashLoanProvider(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    
    // Minimum profit threshold in BNB (0.1 BNB)
    uint256 public constant MIN_PROFIT_THRESHOLD = 0.1 ether;
    // Flash loan fee (0.09%)
    uint256 public constant FLASH_LOAN_FEE = 9;
    // Gas cost buffer (0.01 BNB)
    uint256 public constant GAS_COST_BUFFER = 0.01 ether;
    
    // Events
    event FrontrunExecuted(
        address indexed targetToken,
        uint256 amountIn,
        uint256 profit,
        uint256 gasCost
    );
    
    event ProfitWithdrawn(
        address indexed token,
        uint256 amount
    );
    
    // Track gas costs
    mapping(address => uint256) public gasCosts;
    
    // Constructor
    constructor() Ownable() {}
    
    // Main frontrunning function
    function executeFrontrun(
        address targetToken,
        uint256 amountIn,
        uint256 minProfit,
        address[] calldata path
    ) external nonReentrant {
        require(path.length >= 2, "Invalid path");
        require(amountIn > 0, "Amount must be greater than 0");
        
        // Calculate total costs (flash loan fee + gas buffer)
        uint256 totalCosts = (amountIn * FLASH_LOAN_FEE) / 10000 + GAS_COST_BUFFER;
        require(minProfit >= totalCosts, "Profit must cover costs");
        
        // Get the pair address
        address pair = PANCAKE_FACTORY.getPair(path[0], path[1]);
        require(pair != address(0), "Pair does not exist");
        
        // Get current reserves
        (uint112 reserve0, uint112 reserve1,) = IPancakePair(pair).getReserves();
        
        // Calculate expected output
        uint256 expectedOutput = calculateExpectedOutput(
            amountIn,
            reserve0,
            reserve1,
            path[0] == IPancakePair(pair).token0()
        );
        
        // Ensure profit meets threshold after costs
        require(expectedOutput > amountIn + minProfit + totalCosts, "Insufficient profit");
        
        // Execute flash loan
        bytes memory data = abi.encode(path, minProfit);
        require(FLASH_LOAN_PROVIDER.flashLoan(path[0], amountIn, data), "Flash loan failed");
        
        // Update gas costs
        gasCosts[targetToken] = gasleft();
    }
    
    // Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        require(msg.sender == address(FLASH_LOAN_PROVIDER), "Unauthorized");
        
        (address[] memory path, uint256 minProfit) = abi.decode(data, (address[], uint256));
        
        // Execute the trade
        IERC20(token).approve(address(PANCAKE_ROUTER), amount);
        
        uint256[] memory amounts = PANCAKE_ROUTER.swapExactTokensForTokens(
            amount,
            amount + minProfit,
            path,
            address(this),
            block.timestamp + 300
        );
        
        // Calculate actual profit
        uint256 profit = amounts[amounts.length - 1] - amount - fee;
        require(profit >= minProfit, "Profit below minimum");
        
        // Repay flash loan
        IERC20(token).transfer(address(FLASH_LOAN_PROVIDER), amount + fee);
        
        emit FrontrunExecuted(token, amount, profit, gasCosts[token] - gasleft());
        
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
    
    // Calculate expected output using constant product formula
    function calculateExpectedOutput(
        uint256 amountIn,
        uint112 reserveIn,
        uint112 reserveOut,
        bool isToken0
    ) public pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 9975;
        uint256 numerator = amountInWithFee * (isToken0 ? reserveOut : reserveIn);
        uint256 denominator = (isToken0 ? reserveIn : reserveOut) * 10000 + amountInWithFee;
        return numerator / denominator;
    }
    
    // Withdraw profits
    function withdrawProfits(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No profits to withdraw");
        
        IERC20(token).transfer(owner(), balance);
        emit ProfitWithdrawn(token, balance);
    }
    
    // Emergency withdraw
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }
    
    // Receive BNB
    receive() external payable {}
} 