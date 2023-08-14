// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./LaunchpadModel.sol";
import "./LockWallet.sol";
import "./ISmartChef.sol";
import "./IERC20.sol";

contract Launchpad is Ownable {
    using SafeMath for uint256;

    uint256 public projectIdSeed;
    uint256 public stakeValidationPeriod = 10 minutes;

    mapping(uint256 => LaunchpadProject) projects;
    StakeTokenRequirement[] public stakeTokenList;
    mapping(address => uint) stakeTokenIndex;
    mapping(address => TransactionHistory[]) public userTransactions;
    uint256[] public projectIDList;
    
    constructor() {
        projectIdSeed = 1;
    }
    

    function setStakePeriod(uint256 newPeriod) external onlyOwner {
        stakeValidationPeriod = newPeriod;
    }

    function addProject(
            string memory projectName,
            string memory description,
            address token,
            uint projectType, 
            address master,
            address fundToken,
            uint256[] memory additionalParams, //fundRatio-tokenOnSale-minimumAllocation-maximumAllocation-saleTime-endTime-processTime
            uint8 monthLock,
            uint16 preClaimRatio,
            uint256 ratio 
        ) external onlyOwner {
        LaunchpadProject storage project = projects[projectIdSeed];
        project.ID = projectIdSeed;
        project.projectName=projectName;
        project.description=description;
        project.projectType = ProjectType(projectType);
        project.token = token;
        project.master = master;
        project.ratio = ratio;
        project.fundToken = fundToken;
        project.fundTokenRatio = additionalParams[0];
        project.tokenOnSale = additionalParams[1];
        project.saleTime = additionalParams[4];
        project.endTime = additionalParams[5];
        project.processTime = additionalParams[6];
        project.monthLock = monthLock;
        project.preClaimRatio = preClaimRatio;

        if (project.projectType == ProjectType.PRIVATE){
            project.privateSaleDetail.tokenRemain = additionalParams[1];
            project.privateSaleDetail.whitelists.push();
            project.privateSaleDetail.maximumSlot = additionalParams[1].div(additionalParams[3]) + 1;
            project.privateSaleDetail.minimumAllocation = additionalParams[2];
            project.privateSaleDetail.maximumAllocation = additionalParams[3];
        }else {
            for (uint i = 0 ; i < 6 ; i++){
                project.publicSaleDetail.tokenAllocation.push();
            }
        }
        projectIDList.push(projectIdSeed);
        ++projectIdSeed;
    }

    function updateProject(
            uint256 projectId, 
            address token, 
            address master,
            address fundToken,
            uint256[] memory additionalParams, //fundRatio-tokenOnSale-minimumAllocation-maximumAllocation-saleTime-endTime-processTime
            uint8 monthLock,
            uint16 preClaimRatio
        ) external onlyOwner {
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        project.token = token;
        project.master = master;
        project.fundToken = fundToken;
        project.fundTokenRatio = additionalParams[0];
        if (project.projectType == ProjectType.PRIVATE){
            if (additionalParams[1] < project.tokenOnSale){
                uint256 offset = project.tokenOnSale - additionalParams[1];
                (,project.privateSaleDetail.tokenRemain) = project.privateSaleDetail.tokenRemain.trySub(offset);
            }else {
                uint256 offset = additionalParams[1] - project.tokenOnSale;
                project.privateSaleDetail.tokenRemain += offset;
            }
            project.privateSaleDetail.maximumSlot = additionalParams[1].div(additionalParams[3]) + 1;
            project.privateSaleDetail.minimumAllocation = additionalParams[2];
            project.privateSaleDetail.maximumAllocation = additionalParams[3];
        }
        project.tokenOnSale = additionalParams[1];
        project.saleTime = additionalParams[4];
        project.endTime = additionalParams[5];
        project.processTime = additionalParams[6];
        project.monthLock = monthLock;
        project.preClaimRatio = preClaimRatio;
    }

    function updatePublicSaleTokenAllocation(uint256 projectId, uint256[] memory tokenAllocation) external onlyOwner {
        require(tokenAllocation.length == 5, "NUMBER_OF_STATUS");
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.projectType == ProjectType.PUBLIC, "INVALID_PROJECT_TYPE");
        for (uint8 i = 0 ; i < 5 ; i++){
            project.publicSaleDetail.tokenAllocation[i + 1] = tokenAllocation[i];
        }
    }

    function updateStakeTokenRequirement(address smartChef, uint256[] memory lpAllocation) external onlyOwner {
        uint tokenIndex = stakeTokenIndex[smartChef];
        if (tokenIndex == 0){
            StakeTokenRequirement memory requirement = StakeTokenRequirement(smartChef, lpAllocation);
            stakeTokenIndex[smartChef] = stakeTokenList.length;
            stakeTokenList.push(requirement);
        }else {
            StakeTokenRequirement storage requirement = stakeTokenList[tokenIndex];
            requirement.statusAllocation = lpAllocation;
        }
    }

    function removeStakeTokenRequirement(address smartChef) external onlyOwner {
        uint tokenIndex = stakeTokenIndex[smartChef];
        if (tokenIndex > 0) {
            delete stakeTokenIndex[smartChef];
            stakeTokenList[tokenIndex] = stakeTokenList[stakeTokenList.length - 1];
            stakeTokenList.pop();
        }
    }

    function removeProject(uint256 projectId) external onlyOwner {
        require(projects[projectId].ID != 0, "PROJECT_ID_EXIST");
        delete projects[projectId];
    }

    function addWhitelist(uint256 projectId, address user) external onlyOwner {
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.projectType == ProjectType.PRIVATE);
        uint256 whitelistIndex = project.privateSaleDetail.whitelistIndexes[user];
        if (whitelistIndex == 0){
            require(project.privateSaleDetail.whitelists.length < project.privateSaleDetail.maximumSlot, "MAXIMUM_SLOT_HIT");
            project.privateSaleDetail.whitelists.push(user);
            project.privateSaleDetail.whitelistIndexes[user] = project.privateSaleDetail.whitelists.length - 1;
        }
    }

    function removeWhitelist(uint256 projectId, address user) external onlyOwner {
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.projectType == ProjectType.PRIVATE);
        uint256 whitelistIndex = project.privateSaleDetail.whitelistIndexes[user];
        if (whitelistIndex != 0){
            delete project.privateSaleDetail.whitelistIndexes[user];
            project.privateSaleDetail.whitelists[whitelistIndex] = project.privateSaleDetail.whitelists[project.privateSaleDetail.whitelists.length - 1];
            project.privateSaleDetail.whitelists.pop();
        }
    }

    function endProject(uint256 projectId) external onlyOwner {
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        project.endTime = block.timestamp;
        project.processTime = block.timestamp;
    }

    function getAllLaunchpadProject() external view returns(LaunchpadPrivateVM[] memory projectVM){
        LaunchpadPrivateVM[] memory responseProjectList;
        for(uint8 i = 0; i < projectIDList.length; i++){
            LaunchpadProject storage project = projects[projectIDList[i]];
            responseProjectList.push(LaunchpadPrivateVM(
                project.ID,
                project.token,
                project.master,
                project.fundToken,
                project.fundTokenRatio,
                project.tokenOnSale,
                project.privateSaleDetail.minimumAllocation,
                project.privateSaleDetail.maximumAllocation,
                project.saleTime,
                project.endTime,
                project.processTime,
                project.totalDeposit,
                project.privateSaleDetail.tokenRemain,
                project.privateSaleDetail.whitelists,
                project.projectName,
                project.description
            ));
        }
        return responseProjectList;
    }
    function getProjectPrivateDetail(uint256 projectId) external view returns(LaunchpadPrivateVM memory projectVM){
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.projectType == ProjectType.PRIVATE);
        projectVM = LaunchpadPrivateVM(
            project.ID,
            project.token,
            project.master,
            project.fundToken,
            project.fundTokenRatio,
            project.tokenOnSale,
            project.privateSaleDetail.minimumAllocation,
            project.privateSaleDetail.maximumAllocation,
            project.saleTime,
            project.endTime,
            project.processTime,
            project.totalDeposit,
            project.privateSaleDetail.tokenRemain,
            project.privateSaleDetail.whitelists,
            project.projectName,
            project.description
        );
    }

    function getProjectPublicDetail(uint256 projectId) external view returns(LaunchpadPublicVM memory projectVM){
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.projectType == ProjectType.PUBLIC);
        projectVM = LaunchpadPublicVM(
            project.ID,
            project.token,
            project.master,
            project.fundToken,
            project.fundTokenRatio,
            project.tokenOnSale,
            project.saleTime,
            project.endTime,
            project.processTime,
            project.totalDeposit,
            project.publicSaleDetail.tokenAllocation,
            project.projectName,
            project.description
        );
    }

    function getUserTransaction(address user) external view returns(TransactionHistory[] memory){
        return userTransactions[user];
    }

    function getProjectTransaction(uint256 projectId) external view returns(TransactionHistory memory){
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        return project.txHistories[msg.sender];
    }

    function processPrivateSale(uint256 projectId, uint256 amount) external {
        require(amount > 0, "NON_ZERO_AMOUNT");
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.projectType == ProjectType.PRIVATE, "INVALID_PROJECT_TYPE");
        require(block.timestamp >= project.saleTime && block.timestamp <= project.endTime, "TIME_REQUIREMENT");
        uint256 whitelistIndex = project.privateSaleDetail.whitelistIndexes[msg.sender];
        require(whitelistIndex != 0, "WHITELIST_REQUIREMENT");
        require(project.txHistories[msg.sender].tokenAmount == 0, "ALREADY_BOUGHT");
        uint256 tokenAllocation;
        uint8 fundTokenDecimal = IERC20(project.fundToken).decimals();
        uint8 tokenDecimal = IERC20(project.token).decimals();
        if (fundTokenDecimal <= tokenDecimal) {
            tokenAllocation = amount.mul(10** (tokenDecimal - fundTokenDecimal)).mul(project.fundTokenRatio).div(1e18);
        }else {
            tokenAllocation = amount.mul(project.fundTokenRatio).div(10 ** (fundTokenDecimal - tokenDecimal)).div(1e18);
        }
        require(tokenAllocation >= project.privateSaleDetail.minimumAllocation, "MINIMUM_ALLOCATION");
        require(tokenAllocation <= project.privateSaleDetail.maximumAllocation, "MAXIMUM_ALLOCATION");
        require(tokenAllocation <= project.privateSaleDetail.tokenRemain, "OUT_OF_STOCK");
        (,project.privateSaleDetail.tokenRemain) = project.privateSaleDetail.tokenRemain.trySub(project.privateSaleDetail.maximumAllocation);
        IERC20(project.fundToken).transferFrom(msg.sender, project.master, amount);
        project.totalDeposit += tokenAllocation;
        project.txHistories[msg.sender] = TransactionHistory(projectId, address(0), tokenAllocation, amount, false);
        userTransactions[msg.sender].push(project.txHistories[msg.sender]);
        emit UserProcessPrivateSale(msg.sender, projectId, tokenAllocation, amount, block.timestamp);
    }

    function processPublicSale(uint256 projectId, uint256 amount) external payable {
        /*
        * ratio = price
        fund token ratio: limit per loyalty point
        */
        require(amount > 0, "NON_ZERO_AMOUNT");
        require(msg.value > 0 ether, "You need to send ETH to commit the launchpad");
        LaunchpadProject storage project = projects[projectId];
        IERC20 fundToken;
        if(project.fundToken){
            fundToken = IERC20(project.fundToken);
        }
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.projectType == ProjectType.PUBLIC, "INVALID_PROJECT_TYPE");
        require(block.timestamp >= project.saleTime && block.timestamp <= project.endTime, "TIME_REQUIREMENT");
        require(project.txHistories[msg.sender].tokenAmount == 0, "ALREADY_BOUGHT");

        uint8 tokenDecimal = IERC20(project.token).decimals();
        uint256 userAmountToCommit = msg.value.mul(project.ratio).div(1e18).mul(10 ** tokenDecimal);
        //get the maximum that user can commit
        uint256 userMaximumAmount = project.fundTokenRatio.mul(amount);
        require(userMaximumAmount > userAmountToCommit, "Your maximum commitment is "+userMaximumAmount.div(project.ratio));
        if(project.fundToken){
            IERC20(project.fundToken).transferFrom(msg.sender, address(this), amount);
        }
        project.totalDeposit += msg.value;
        project.txHistories[msg.sender] = TransactionHistory(projectId, msg.sender, userAmountToCommit, msg.value, amount, false);
        userTransactions[msg.sender].push(project.txHistories[msg.sender]);
        
    }

    function getUserStatus(address user) public view returns(uint8) {
        uint8 status = 0;
        for (uint i = 0 ; i < stakeTokenList.length ; i++){
            DepositHistory[] memory depositHistories = ISmartChef(stakeTokenList[i].smartChef).getDepositHistory(user);
            for (uint j = 0 ; j < depositHistories.length ; j++){
                if (block.timestamp.sub(depositHistories[j].timestamp) < stakeValidationPeriod) {
                    break;
                }
                for (uint8 k = 0 ; k < stakeTokenList[i].statusAllocation.length ; k++){
                    if (depositHistories[j].amount >= stakeTokenList[i].statusAllocation[k]){
                        if (status < k + 1){
                            status = k + 1;
                        }
                        continue;
                    }
                    break;
                }
                if (status == 5){
                    break;          
                }
            }
            if (status == 5) {
                break;          
            }
        }
        return status;
    }

    function processPostPrivateSale(uint256 projectId) external {
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.projectType == ProjectType.PRIVATE);
        require(block.timestamp > project.processTime, "TIME_REQUIREMENT");
        TransactionHistory storage txHistory = project.txHistories[msg.sender];
        require(txHistory.tokenAmount > 0, "NOTHING_TO_CLAIM");
        require(!txHistory.processed, "ALREADY_PROCESSED");
        txHistory.processed = true;
        if (project.monthLock == 0 || project.preClaimRatio >= 1e4){
            IERC20(project.token).transfer(msg.sender, txHistory.tokenAmount);
        }else {
            uint256 preClaimTokenAmount = txHistory.tokenAmount.mul(project.preClaimRatio).div(1e4);
            IERC20(project.token).transfer(msg.sender, preClaimTokenAmount);
            uint256 lockTokenAmount = txHistory.tokenAmount.sub(preClaimTokenAmount);
            txHistory.lockWallet = address(new LockWallet(msg.sender, project.token, lockTokenAmount, preClaimTokenAmount, preClaimTokenAmount, project.monthLock, project.endTime));
            IERC20(project.token).transfer(txHistory.lockWallet, lockTokenAmount);
        }

        emit UserProcessPostPrivateSale(msg.sender, projectId, txHistory.tokenAmount, txHistory.depositAmount, txHistory.lockWallet, block.timestamp);
    }

    function processPostPublicSale(uint256 projectId) external {
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.projectType == ProjectType.PUBLIC);
        require(block.timestamp > project.processTime, "TIME_REQUIREMENT");
        TransactionHistory storage txHistory = project.txHistories[msg.sender];
        require(txHistory.tokenAmount > 0, "NOTHING_TO_CLAIM");
        require(!txHistory.processed, "ALREADY_PROCESSED");
        txHistory.processed = true;
        uint256 tokenAllocation = txHistory.tokenAmount;
        uint256 depositPayback = 0;
        uint256 fundTokenPayback = 0;
        if (project.totalDeposit > project.tokenOnSale){
            tokenAllocation = tokenAllocation.mul(project.tokenOnSale).div(project.totalDeposit);
            depositPayback = txHistory.depositAmount.mul(project.totalDeposit.sub(project.tokenOnSale)).div(project.totalDeposit);
            fundTokenPayback = txHistory.fundTokenAmount.mul(project.totalDeposit.sub(project.tokenOnSale)).div(project.totalDeposit);

        }
        
        if (project.monthLock == 0 || project.preClaimRatio >= 1e4){
            IERC20(project.token).transfer(msg.sender, tokenAllocation);
        }else {
            uint256 preClaimTokenAmount = tokenAllocation.mul(project.preClaimRatio).div(1e4);
            IERC20(project.token).transfer(msg.sender, preClaimTokenAmount);
            uint256 lockTokenAmount = tokenAllocation.sub(preClaimTokenAmount);
            txHistory.lockWallet = address(new LockWallet(msg.sender, project.token, lockTokenAmount, preClaimTokenAmount, preClaimTokenAmount, project.monthLock, project.endTime));
            IERC20(project.token).transfer(txHistory.lockWallet, lockTokenAmount);
        }
        if (depositPayback > 0){
            IERC20(project.fundToken).transfer(msg.sender, fundTokenPayback);
            msg.sender.transfer(depositPayback);
        }

        emit UserProcessPostPublicSale(msg.sender, projectId, tokenAllocation, txHistory.depositAmount, depositPayback, txHistory.lockWallet, block.timestamp);
    }

    function withdrawRemainingToken(uint256 projectId) external onlyOwner {
        LaunchpadProject storage project = projects[projectId];
        require(project.ID != 0, "PROJECT_ID_EXIST");
        require(project.endTime < block.timestamp, "TIME_REQUIREMENT");
        require(!project.processedEndSale, "ALREADY_PROCESSED");
        project.processedEndSale = true;
        uint256 tokenRemain;
        uint256 fundTokenAmount;
        uint8 fundTokenDecimal = IERC20(project.fundToken).decimals();
        uint8 tokenDecimal = IERC20(project.token).decimals();
        
        if (project.totalDeposit < project.tokenOnSale){
            tokenRemain = project.tokenOnSale.sub(project.totalDeposit);
            IERC20(project.token).transfer(project.master, tokenRemain);
            fundTokenAmount = project.totalDeposit.mul(1e18).div(project.fundTokenRatio);
        }else {
            fundTokenAmount = project.tokenOnSale.mul(1e18).div(project.fundTokenRatio);
        }

        if (fundTokenDecimal <= tokenDecimal) {
            fundTokenAmount = fundTokenAmount.div(10 ** (tokenDecimal - fundTokenDecimal));
        }else {
            fundTokenAmount = fundTokenAmount.mul(10 ** (fundTokenDecimal - tokenDecimal));
        }
        IERC20(project.fundToken).transfer(project.master, fundTokenAmount);
        emit MasterWithdrawRemainToken(projectId, tokenRemain, fundTokenAmount, block.timestamp);
    }

    event UserProcessPrivateSale(address indexed user, uint256 projectId, uint256 tokenAllocation, uint256 fundTokenAmount, uint256 timestamp);
    event UserProcessPublicSale(address indexed user, uint256 projectId, uint8 currentUserStatus, uint256 tokenAllocation, uint256 fundTokenAmount, uint256 timestamp);
    event UserProcessPostPrivateSale(address indexed user, uint256 projectId, uint256 tokenAllocation, uint256 fundTokenAmount, address lockWallet, uint256 timestamp);
    event UserProcessPostPublicSale(address indexed user, uint256 projectId, uint256 tokenAllocation, uint256 fundTokenAmount, uint256 fundTokenPayback, address lockWallet, uint256 timestamp);
    event MasterWithdrawRemainToken(uint256 indexed projectId, uint256 tokenRemain, uint256 amount, uint256 timestamp);
}