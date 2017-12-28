pragma solidity ^0.4.18;

import "./IOracleFactory.sol";
import "./CentralizedOracle.sol";
import "./DecentralizedOracle.sol";
import "../storage/IAddressManager.sol";

contract OracleFactory is IOracleFactory {
    uint16 public version;
    address private addressManager;
    mapping(bytes32 => address) public oracles;

    // Events
    event CentralizedOracleCreated(
        uint16 indexed _version, 
        address indexed _contractAddress, 
        address indexed _eventAddress, 
        address _oracle,
        bytes32[10] _name, 
        bytes32[10] _resultNames, 
        uint8 _numOfResults,
        uint256 _bettingStartBlock, 
        uint256 _bettingEndBlock, 
        uint256 _resultSettingStartBlock,
        uint256 _resultSettingEndBlock, 
        uint256 _consensusThreshold);
    event DecentralizedOracleCreated(
        uint16 indexed _version, 
        address indexed _contractAddress, 
        address indexed _eventAddress, 
        bytes32[10] _name, 
        bytes32[10] _resultNames, 
        uint8 _numOfResults, 
        uint8 _lastResultIndex, 
        uint256 _arbitrationEndBlock, 
        uint256 _consensusThreshold);

    /*
    * @notice Creates new OracleFactory contract.
    * @param _addressManager The address of the AddressManager contract.
    */
    function OracleFactory(address _addressManager) public {
        require(_addressManager != address(0));

        addressManager = _addressManager;
        version = IAddressManager(addressManager).currentOracleFactoryIndex();
    }

    function createCentralizedOracle(
        address _oracle,
        address _eventAddress,
        bytes32[10] _eventName,
        bytes32[10] _eventResultNames,
        uint8 _numOfResults,
        uint256 _bettingStartBlock,
        uint256 _bettingEndBlock,
        uint256 _resultSettingStartBlock,
        uint256 _resultSettingEndBlock,
        uint256 _consensusThreshold) 
        public
        returns (address)
    {
        bytes32 hash = getCentralizedOracleHash(_oracle, _eventAddress, _eventName, _eventResultNames, 
            _numOfResults, _bettingStartBlock, _bettingEndBlock, _resultSettingStartBlock, _resultSettingEndBlock, 
            _consensusThreshold);
        // CentralizedOracle should not exist yet
        require(oracles[hash] == address(0));

        CentralizedOracle cOracle = new CentralizedOracle(version, msg.sender, _oracle, _eventAddress, 
            _eventName, _eventResultNames, _numOfResults, _bettingStartBlock, _bettingEndBlock, _resultSettingStartBlock, 
            _resultSettingEndBlock, _consensusThreshold);
        oracles[hash] = address(cOracle);

        CentralizedOracleCreated(version, address(cOracle), _eventAddress, _oracle, _eventName, _eventResultNames, 
            _numOfResults, _bettingStartBlock, _bettingEndBlock, _resultSettingStartBlock, _resultSettingEndBlock, 
            _consensusThreshold);

        return address(cOracle);
    }

    function createDecentralizedOracle(
        address _eventAddress,
        bytes32[10] _eventName, 
        bytes32[10] _eventResultNames, 
        uint8 _numOfResults,
        uint8 _lastResultIndex,
        uint256 _arbitrationEndBlock,
        uint256 _consensusThreshold)
        public
        returns (address)
    {
        bytes32 hash = getDecentralizedOracleHash(_eventAddress, _eventName, _eventResultNames, _numOfResults, 
            _lastResultIndex, _arbitrationEndBlock, _consensusThreshold);
        // DecentralizedOracle should not exist yet
        require(oracles[hash] == address(0));

        DecentralizedOracle dOracle = new DecentralizedOracle(version, msg.sender, _eventAddress, _eventName, 
            _eventResultNames, _numOfResults, _lastResultIndex, _arbitrationEndBlock, _consensusThreshold);
        oracles[hash] = address(dOracle);

        DecentralizedOracleCreated(version, address(dOracle), _eventAddress, _eventName, _eventResultNames,
             _numOfResults, _lastResultIndex, _arbitrationEndBlock, _consensusThreshold);

        return address(dOracle);
    }

    function getCentralizedOracleHash(
        address _oracle,
        address _eventAddress,
        bytes32[10] _eventName, 
        bytes32[10] _eventResultNames, 
        uint8 _numOfResults,
        uint256 _bettingStartBlock,
        uint256 _bettingEndBlock,
        uint256 _resultSettingStartBlock,
        uint256 _resultSettingEndBlock,
        uint256 _consensusThreshold) 
        private
        pure
        returns (bytes32)
    {
        return keccak256(_oracle, _eventAddress, _eventName, _eventResultNames, _numOfResults, _bettingStartBlock, 
            _bettingEndBlock, _resultSettingStartBlock, _resultSettingEndBlock, _consensusThreshold);
    }

    function getDecentralizedOracleHash(
        address _eventAddress,
        bytes32[10] _eventName, 
        bytes32[10] _eventResultNames, 
        uint8 _numOfResults,
        uint8 _lastResultIndex,
        uint256 _arbitrationEndBlock,
        uint256 _consensusThreshold) 
        private
        pure
        returns (bytes32)
    {
        return keccak256(_eventAddress, _eventName, _eventResultNames, _numOfResults, _lastResultIndex, 
            _arbitrationEndBlock, _consensusThreshold);
    }
}
