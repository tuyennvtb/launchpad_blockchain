// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

enum ProjectType { PRIVATE, PUBLIC }

struct LaunchpadProject {
    uint256 ID;
    address token;
    ProjectType projectType;
    address master;
    address fundToken;
    uint256 fundTokenRatio;
    uint256 tokenOnSale;
    uint256 saleTime;
    uint256 endTime;
    uint256 processTime;
    uint256 totalDeposit;
    uint8 monthLock;
    uint16 preClaimRatio;

    LaunchpadPrivate privateSaleDetail;
    LaunchpadPublic publicSaleDetail;
    mapping(address => TransactionHistory) txHistories;
    bool processedEndSale;
}

struct LaunchpadPrivate {
    uint256 minimumAllocation;
    uint256 maximumAllocation;
    uint256 tokenRemain;
    address[] whitelists;
    mapping(address => uint256) whitelistIndexes;
    uint256 maximumSlot;
}

struct LaunchpadPublic {
    uint256[] tokenAllocation;
}

struct StakeTokenRequirement {
    address smartChef;
    uint256[] statusAllocation; 
}

struct LaunchpadPrivateVM {
    uint256 ID;
    address token;
    address master;
    address fundToken;
    uint256 fundTokenRatio;
    uint256 tokenOnSale;
    uint256 minimumAllocation;
    uint256 maximumAllocation;
    uint256 saleTime;
    uint256 endTime;
    uint256 processTime;
    uint256 totalDeposit;
    uint256 tokenRemain;
    address[] whitelists;
}

struct LaunchpadPublicVM {
    uint256 ID;
    address token;
    address master;
    address fundToken;
    uint256 fundTokenRatio;
    uint256 tokenOnSale;
    uint256 saleTime;
    uint256 endTime;
    uint256 processTime;
    uint256 totalDeposit;
    uint256[] tokenAllocation;
}

struct TransactionHistory {
    uint256 projectId;
    address lockWallet;
    uint256 tokenAmount;
    uint256 depositAmount;
    bool processed;
}