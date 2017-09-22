pragma solidity ^0.4.15;

import "./Oracle.sol";

contract TopicOracle is Oracle {
    bytes32 public name;
    bytes32[] public resultNames;
    uint256 public bettingEndBlock;

    function TopicOracle(
        bytes32 _name, 
        bytes32[] _resultNames, 
        uint256 _bettingEndBlock,
        uint256 _stakingEndBlock,
        uint256 _decisionEndBlock) 
        Oracle(_stakingEndBlock, _bettingEndBlock, _decisionEndBlock)
        public
    {
        require(_name.length > 0);
        require(_resultNames.length > 1);
        require(_bettingEndBlock > block.number);

        name = _name;

        for (uint i = 0; i < _resultNames.length; i++) {
            resultNames.push(_resultNames[i]);
        }

        bettingEndBlock = _bettingEndBlock;
    }
}
