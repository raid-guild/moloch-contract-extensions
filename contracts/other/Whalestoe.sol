pragma solidity ^0.5.0;


import "./MolochV2.sol";

contract MolochToken {
    Moloch public moloch;
    string public constant name = 'RaidGuild DAM Token';
    string public constant symbol = 'RDT';
    uint8 public constant decimals = 0;

    constructor(address _moloch) public {
        moloch = Moloch(_moloch);
    }
    
    function totalSupply() public view returns (uint256) {
        return moloch.totalShares();
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 shares;
        (,shares,,,,) = moloch.members(account);
        return shares;
    }

}