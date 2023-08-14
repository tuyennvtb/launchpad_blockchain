// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

enum ProjectType { PRIVATE, PUBLIC }

struct LaunchpadProject {
    uint256 ID;
    address token;
    string projectName;
    string description;
    ProjectType projectType;
    address master;
    uint256 ratio;
    uint256 tokenOnSale;
    uint256 saleTime;
    uint256 endTime;
    uint256 processTime;
    uint256 totalDeposit;
    uint8 monthLock;
    uint16 preClaimRatio;
    bool requireFundToken;
    address fundToken;
    uint256 fundTokenRatio; 
    uint256 fundAmountInETH;
    

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
    string projectName;
    string description;
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
    uint256 fundAmountInETH;
}

struct LaunchpadPublicVM {
    uint256 ID;
    string projectName;
    string description;
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
    uint256 fundAmountInETH;
}

struct TransactionHistory {
    uint256 projectId;
    address lockWallet;
    uint256 tokenAmount;
    uint256 depositAmount;
    uint256 fundTokenAmount;
    bool processed;
}