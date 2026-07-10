// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Poll {
        string description;
        uint256 deadline;
        uint256 optionCount;
        bool exists;
    }

    uint256 public pollCount;
    mapping(uint256 => Poll) public polls;
    mapping(uint256 => mapping(uint256 => uint256)) public voteCounts;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event PollCreated(
        uint256 indexed pollId,
        string description,
        string[] options,
        uint256 deadline
    );
    event Voted(
        uint256 indexed pollId,
        address indexed voter,
        uint256 optionIndex
    );

    function createPoll(
        string calldata _description,
        string[] calldata _options,
        uint256 _durationMinutes
    ) external returns (uint256 pollId) {
        require(_options.length >= 2, "need at least 2 options");
        require(_durationMinutes > 0, "duration must be > 0");

        pollId = pollCount;
        pollCount++;

        uint256 deadline = block.timestamp + _durationMinutes * 1 minutes;

        polls[pollId] = Poll({
            description: _description,
            deadline: deadline,
            optionCount: _options.length,
            exists: true
        });

        emit PollCreated(pollId, _description, _options, deadline);
    }

    function vote(uint256 _pollId, uint256 _optionIndex) external {
        Poll storage poll = polls[_pollId];
        require(poll.exists, "poll not found");
        require(block.timestamp < poll.deadline, "poll ended");
        require(!hasVoted[_pollId][msg.sender], "already voted");
        require(_optionIndex < poll.optionCount, "invalid option");

        voteCounts[_pollId][_optionIndex]++;
        hasVoted[_pollId][msg.sender] = true;

        emit Voted(_pollId, msg.sender, _optionIndex);
    }

    function getResult(uint256 _pollId)
        external
        view
        returns (uint256[] memory results)
    {
        Poll storage poll = polls[_pollId];
        require(poll.exists, "poll not found");

        results = new uint256[](poll.optionCount);
        for (uint256 i = 0; i < poll.optionCount; i++) {
            results[i] = voteCounts[_pollId][i];
        }
    }
}
