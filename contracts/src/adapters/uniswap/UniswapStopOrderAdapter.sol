// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVaultActionAdapter.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract UniswapStopOrderAdapter is IVaultActionAdapter, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable executor;
    IUniswapV2Router02 public router;

    event RouterUpdated(address indexed router);
    event Executed(
        uint256 indexed ruleId, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    error UnauthorizedExecutor(address caller);
    error InvalidAddress();
    error InvalidSwapPath();

    modifier onlyExecutor() {
        if (msg.sender != executor) {
            revert UnauthorizedExecutor(msg.sender);
        }
        _;
    }

    constructor(address _owner, address _executor, address _router) Ownable(_owner) {
        if (_executor == address(0) || _router == address(0)) {
            revert InvalidAddress();
        }
        executor = _executor;
        router = IUniswapV2Router02(_router);
    }

    function setRouter(address _router) external onlyOwner {
        if (_router == address(0)) {
            revert InvalidAddress();
        }
        router = IUniswapV2Router02(_router);
        emit RouterUpdated(_router);
    }

    function execute(uint256 ruleId, bytes calldata data)
        external
        override
        onlyExecutor
        nonReentrant
        returns (bytes memory)
    {
        (address tokenIn, address tokenOut, uint256 amountIn, uint256 minOut, address recipient, uint256 deadline) =
            abi.decode(data, (address, address, uint256, uint256, address, uint256));

        if (tokenIn == address(0) || tokenOut == address(0) || recipient == address(0)) {
            revert InvalidAddress();
        }
        if (tokenIn == tokenOut) {
            revert InvalidSwapPath();
        }

        IERC20(tokenIn).forceApprove(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = router.swapExactTokensForTokens(amountIn, minOut, path, recipient, deadline);

        emit Executed(ruleId, tokenIn, tokenOut, amountIn, amounts[amounts.length - 1]);
        return abi.encode(amounts);
    }

    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    function withdrawEth(address payable to, uint256 amount) external onlyOwner {
        (bool ok,) = to.call{value: amount}("");
        require(ok, "WITHDRAW_ETH_FAILED");
    }

    receive() external payable {}
}
