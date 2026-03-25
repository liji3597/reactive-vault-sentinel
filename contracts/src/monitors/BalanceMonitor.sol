// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BalanceMonitor is Ownable2Step {
    event BalanceChanged(address indexed account, address indexed token, uint256 oldBalance, uint256 newBalance);

    mapping(address => mapping(address => uint256)) public lastKnownBalance;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function checkpoint(address account, address token) external {
        uint256 oldBalance = lastKnownBalance[account][token];
        uint256 newBalance = _readBalance(account, token);
        if (newBalance != oldBalance) {
            lastKnownBalance[account][token] = newBalance;
            emit BalanceChanged(account, token, oldBalance, newBalance);
        }
    }

    function _readBalance(address account, address token) internal view returns (uint256) {
        if (token == address(0)) {
            return account.balance;
        }
        return IERC20(token).balanceOf(account);
    }
}
