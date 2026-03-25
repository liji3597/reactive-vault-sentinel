// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVaultActionAdapter.sol";

contract BasicTransferAdapter is IVaultActionAdapter, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable executor;

    event Executed(uint256 indexed ruleId, address indexed token, address indexed to, uint256 amount);

    error UnauthorizedExecutor(address caller);
    error InvalidRecipient();
    error InsufficientEthBalance(uint256 balance, uint256 required);

    modifier onlyExecutor() {
        if (msg.sender != executor) {
            revert UnauthorizedExecutor(msg.sender);
        }
        _;
    }

    constructor(address _owner, address _executor) Ownable(_owner) {
        executor = _executor;
    }

    function execute(uint256 ruleId, bytes calldata data)
        external
        override
        onlyExecutor
        nonReentrant
        returns (bytes memory)
    {
        (address token, address to, uint256 amount) = abi.decode(data, (address, address, uint256));
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        if (token == address(0)) {
            uint256 balance = address(this).balance;
            if (balance < amount) {
                revert InsufficientEthBalance(balance, amount);
            }
            (bool ok,) = payable(to).call{value: amount}("");
            require(ok, "ETH_TRANSFER_FAILED");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }

        emit Executed(ruleId, token, to, amount);
        return abi.encode(token, to, amount);
    }

    function withdrawEth(address payable to, uint256 amount) external onlyOwner {
        (bool ok,) = to.call{value: amount}("");
        require(ok, "WITHDRAW_ETH_FAILED");
    }

    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    receive() external payable {}
}
