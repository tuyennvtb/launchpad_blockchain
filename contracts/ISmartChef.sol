// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

struct DepositHistory {
    uint256 amount;
    uint256 timestamp;
}

interface ISmartChef {
    function getDepositHistory(address account) external view returns (DepositHistory[] memory);
}