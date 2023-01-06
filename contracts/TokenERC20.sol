// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract TokenERC20 is ERC20 {
    address payable owner;
    uint mintRatio;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = payable(msg.sender);
        super._mint(msg.sender, 100000000000000 * 10 ** 18);
        mintRatio = 10 ** 9;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can make this request");
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    receive() external payable {
        deposit();
    }
  
    function deposit() public payable {
        require(msg.value > 0);
        owner.transfer(msg.value);
        _mint(msg.sender, mintRatio * msg.value);
    }
}