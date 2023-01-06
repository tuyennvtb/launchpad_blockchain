// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./IERC20.sol";

contract LockWallet {
    using SafeMath for uint256;

    address public _owner;
    address public _token;
    uint256 public _amount;
    uint256 public _preClaimAmount;
    uint256 public _claimedAmount;
    uint8 public _monthLock;
    uint256 public _startTime;

    uint256 lockSegmentTime = 10 minutes;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(address owner, address token, uint256 amount, uint256 preClaimAmount, uint256 claimedAmount, uint8 monthLock, uint256 startTime){
        _owner = owner;
        _token = token;
        _amount = amount;
        _preClaimAmount = preClaimAmount;
        _claimedAmount = claimedAmount;
        _monthLock = monthLock;
        _startTime = startTime;
    }

    function getInfo() public view returns(address, address, uint256, uint256, uint256, uint8, uint256, uint){
        uint monthPassed = block.timestamp.sub(_startTime).div(lockSegmentTime);
        if (monthPassed > _monthLock) {
            monthPassed = _monthLock;
        }
        return (_owner, _token, _amount, _preClaimAmount, _claimedAmount, _monthLock, _startTime, monthPassed);
    }

    function getClaimableAmount() public view returns(uint256) {
        uint monthPassed = block.timestamp.sub(_startTime).div(lockSegmentTime);
        if (monthPassed > _monthLock) {
            monthPassed = _monthLock;
        }
        return monthPassed.mul(_amount).div(_monthLock).add(_preClaimAmount).sub(_claimedAmount);
    }

    function claimToken() public onlyOwner {
        uint256 claimableAmount = getClaimableAmount();
        require(claimableAmount > 0, "NOTHING_TO_CLAIM");
        IERC20(_token).transfer(_owner, claimableAmount);
        _claimedAmount += claimableAmount;
        emit Withdraw(block.timestamp, claimableAmount);
    }

    event Withdraw(uint256 _time, uint256 amount);
}