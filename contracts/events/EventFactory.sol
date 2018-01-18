pragma solidity ^0.4.18;

import "../storage/IAddressManager.sol";
import "./TopicEvent.sol";

/// @title Event Factory allows the creation of individual prediction events.
contract EventFactory {
    using ByteUtils for bytes32;

    uint16 public version;
    address private addressManager;
    mapping(bytes32 => TopicEvent) public topics;

    // Events
    event TopicCreated(
        uint16 indexed _version,
        address indexed _topicAddress, 
        bytes32[10] _name, 
        bytes32[11] _resultNames,
        uint8 _numOfResults);

    function EventFactory(address _addressManager) public {
        require(_addressManager != address(0));

        addressManager = _addressManager;
        version = IAddressManager(addressManager).currentEventFactoryIndex();
    }
    
    function createTopic(
        address _oracle, 
        bytes32[10] _name, 
        bytes32[10] _resultNames, 
        uint256 _bettingStartBlock,
        uint256 _bettingEndBlock,
        uint256 _resultSettingStartBlock,
        uint256 _resultSettingEndBlock)
        public
        returns (TopicEvent topicEvent) 
    {
        require(!_name[0].isEmpty());
        require(!_resultNames[0].isEmpty());
        require(!_resultNames[1].isEmpty());
        
        bytes32[11] memory resultNames;
        uint8 numOfResults;

        resultNames[0] = "Invalid";
        numOfResults++;

        for (uint i = 0; i < _resultNames.length; i++) {
            if (!_resultNames[i].isEmpty()) {
                resultNames[i + 1] = _resultNames[i];
                numOfResults++;
            } else {
                break;
            }
        }

        bytes32 topicHash = getTopicHash(_name, resultNames, numOfResults, _bettingStartBlock, _bettingEndBlock, 
            _resultSettingStartBlock, _resultSettingEndBlock);
        // Topic should not exist yet
        require(address(topics[topicHash]) == 0);

        TopicEvent topic = new TopicEvent(version, msg.sender, _oracle, _name, resultNames, numOfResults, 
            _bettingStartBlock, _bettingEndBlock, _resultSettingStartBlock, _resultSettingEndBlock, addressManager);
        topics[topicHash] = topic;

        TopicCreated(version, address(topic), _name, resultNames, numOfResults);

        return topic;
    }

    function getTopicHash(
        bytes32[10] _name, 
        bytes32[11] _resultNames, 
        uint8 _numOfResults,
        uint256 _bettingStartBlock,
        uint256 _bettingEndBlock, 
        uint256 _resultSettingStartBlock,
        uint256 _resultSettingEndBlock)
        internal
        pure    
        returns (bytes32)
    {
        return keccak256(_name, _resultNames, _numOfResults, _bettingStartBlock, _bettingEndBlock, 
            _resultSettingStartBlock, _resultSettingEndBlock);
    }
}
