pragma solidity ^0.4.18;

import "./Oracle.sol";

contract DecentralizedOracle is Oracle {
    uint8 public lastResultIndex;
    uint256 public arbitrationEndBlock;

    /*
    * @notice Creates new DecentralizedOracle contract.
    * @param _version The contract version.
    * @param _owner The address of the owner.
    * @param _eventAddress The address of the Event.
    * @param _numOfResults The number of result options.
    * @param _lastResultIndex The last result index set by the DecentralizedOracle.
    * @param _arbitrationEndBlock The max block of this arbitration that voting will be allowed.
    * @param _consensusThreshold The BOT amount that needs to be reached for this DecentralizedOracle to be valid.
    */
    function DecentralizedOracle(
        uint16 _version,
        address _owner,
        address _eventAddress,
        uint8 _numOfResults,
        uint8 _lastResultIndex,
        uint256 _arbitrationEndBlock,
        uint256 _consensusThreshold)
        Ownable(_owner)
        public
        validAddress(_eventAddress)
    {
        require(_numOfResults > 0);
        require(_arbitrationEndBlock > block.number);
        require(_consensusThreshold > 0);

        version = _version;
        eventAddress = _eventAddress;
        numOfResults = _numOfResults;
        lastResultIndex = _lastResultIndex;
        arbitrationEndBlock = _arbitrationEndBlock;
        consensusThreshold = _consensusThreshold;
    }

    /*
    * @notice Vote on an Event result which requires BOT payment.
    * @param _eventResultIndex The Event result which is being voted on.
    * @param _botAmount The amount of BOT used to vote.
    */
    function voteResult(uint8 _eventResultIndex, uint256 _botAmount) 
        external 
        validResultIndex(_eventResultIndex) 
        isNotFinished()
    {
        require(_botAmount > 0);
        require(block.number < arbitrationEndBlock);
        require(_eventResultIndex != lastResultIndex);

        resultBalances[_eventResultIndex].totalVotes = resultBalances[_eventResultIndex].totalVotes.add(_botAmount);
        resultBalances[_eventResultIndex].votes[msg.sender] = resultBalances[_eventResultIndex].votes[msg.sender]
            .add(_botAmount);

        ITopicEvent(eventAddress).voteFromOracle(_eventResultIndex, msg.sender, _botAmount);
        OracleResultVoted(version, address(this), msg.sender, _eventResultIndex, _botAmount);

        if (resultBalances[_eventResultIndex].totalVotes >= consensusThreshold) {
            setResult();
        }
    }

    /*
    * @notice This can be called by anyone if this VotingOracle did not meet the consensus threshold and has reached 
    *   the arbitration end block. This finishes the Event and allows winners to withdraw their winnings from the Event 
    *   contract.
    * @return Flag to indicate success of finalizing the result.
    */
    function finalizeResult() 
        external 
        isNotFinished()
    {
        require(block.number >= arbitrationEndBlock);

        finished = true;
        resultIndex = lastResultIndex;

        ITopicEvent(eventAddress).decentralizedOracleFinalizeResult();
    }

    /*
    * @dev DecentralizedOracle is validated and set the result of the Event.
    */
    function setResult() 
        private 
    {
        finished = true;

        uint256 winningVoteBalance = 0;
        for (uint8 i = 0; i < numOfResults; i++) {
            uint256 totalVoteBalance = resultBalances[i].totalVotes;
            if (totalVoteBalance > winningVoteBalance) {
                winningVoteBalance = totalVoteBalance;
                resultIndex = i;
            }
        }

        ITopicEvent(eventAddress).decentralizedOracleSetResult(resultIndex, winningVoteBalance);
        OracleResultSet(version, address(this), resultIndex);
    }
}
