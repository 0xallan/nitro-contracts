// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFeeTokenPricer} from "../../../../src/bridge/ISequencerInbox.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGasRefunder} from "../../../../src/libraries/IGasRefunder.sol";

/**
 * @title Test implementation of a fee token pricer that trades on AMM and keeps track of trades
 */
contract AmmTradeTracker is IFeeTokenPricer, IGasRefunder, Ownable {
    IUniswapV2Router01 public immutable router;
    address public immutable token;
    address public immutable weth;

    uint256 public ethAccumulator;
    uint256 public tokenAccumulator;

    constructor(IUniswapV2Router01 _router, address _token) Ownable() {
        router = _router;
        token = _token;
        weth = _router.WETH();

        IERC20(token).approve(address(router), type(uint256).max);
    }

    // @inheritdoc IFeeTokenPricer
    function getExchangeRate() external view returns (uint256) {
        // todo - scale for decimals to get 1e18 denominator
        return tokenAccumulator * 1e18 / ethAccumulator;
    }

    function swapTokenToEth(uint256 tokenAmount) external onlyOwner {
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;

        // todo - properly calculate slippage
        uint256 amountOutMin = 1;
        uint256[] memory amounts = router.swapExactTokensForETH({
            amountIn: tokenAmount,
            amountOutMin: amountOutMin,
            path: path,
            to: msg.sender,
            deadline: block.timestamp
        });
        uint256 ethReceived = amounts[amounts.length - 1];

        ethAccumulator += ethReceived;
        tokenAccumulator += tokenAmount;
    }

    function onGasSpent(address payable spender, uint256 gasUsed, uint256 calldataSize)
        external
        returns (bool success)
    {
        // update internal state
        uint256 exchangeRateUsed = tokenAccumulator * 1e18 / ethAccumulator;

        gasUsed += calldataSize * 16;
        uint256 ethDelta = gasUsed * block.basefee;
        uint256 tokenDelta = ethDelta * exchangeRateUsed / 1e18;

        ethAccumulator -= ethDelta;
        tokenAccumulator -= tokenDelta;

        success = true;
    }
}

interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IERC20 {
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
