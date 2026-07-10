// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Voting.sol";

contract VotingTest is Test {
    Voting public voting;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address dave = makeAddr("dave");

    // Event declarations for expectEmit matching
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

    function setUp() public {
        voting = new Voting();
    }

    // ============ createPoll 组 ============

    // UT-001
    function testCreatePollHappy() public {
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        vm.expectEmit(true, false, false, false);
        emit PollCreated(0, "", new string[](0), 0);

        uint256 pollId = voting.createPoll("Test Poll", options, 10);

        assertEq(pollId, 0);
        assertEq(voting.pollCount(), 1);

        (string memory desc, uint256 deadline, uint256 optCount, bool exists) = voting.polls(0);
        assertEq(desc, "Test Poll");
        assertEq(optCount, 2);
        assertTrue(exists);
        assertEq(deadline, block.timestamp + 10 * 1 minutes);
    }

    // UT-002
    function testCreatePollRevertsTooFewOptions() public {
        string[] memory options = new string[](1);
        options[0] = "Only";

        vm.expectRevert(bytes("need at least 2 options"));
        voting.createPoll("Bad Poll", options, 10);
    }

    // UT-002b
    function testCreatePollRevertsEmptyOptions() public {
        string[] memory options = new string[](0);

        vm.expectRevert(bytes("need at least 2 options"));
        voting.createPoll("Bad Poll", options, 10);
    }

    // UT-003
    function testCreatePollRevertsZeroDuration() public {
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        vm.expectRevert(bytes("duration must be > 0"));
        voting.createPoll("Bad Poll", options, 0);
    }

    // UT-004
    function testCreatePollIncrementsPollId() public {
        string[] memory options = new string[](2);
        options[0] = "A";
        options[1] = "B";

        uint256 id0 = voting.createPoll("Poll 0", options, 10);
        uint256 id1 = voting.createPoll("Poll 1", options, 10);
        uint256 id2 = voting.createPoll("Poll 2", options, 10);

        assertEq(id0, 0);
        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(voting.pollCount(), 3);

        // Verify each poll is independent
        (string memory desc0, , , bool exists0) = voting.polls(0);
        (string memory desc1, , , bool exists1) = voting.polls(1);
        (string memory desc2, , , bool exists2) = voting.polls(2);

        assertEq(desc0, "Poll 0");
        assertEq(desc1, "Poll 1");
        assertEq(desc2, "Poll 2");
        assertTrue(exists0);
        assertTrue(exists1);
        assertTrue(exists2);
    }

    // UT-004b
    function testCreatePollDeadlineIndependent() public {
        string[] memory options = new string[](2);
        options[0] = "A";
        options[1] = "B";

        vm.warp(1000);
        voting.createPoll("Poll at 1000", options, 5);
        ( , uint256 deadline0, , ) = voting.polls(0);
        assertEq(deadline0, 1000 + 5 * 60);

        vm.warp(2000);
        voting.createPoll("Poll at 2000", options, 10);
        ( , uint256 deadline1, , ) = voting.polls(1);
        assertEq(deadline1, 2000 + 10 * 60);

        // Verify independence: first poll deadline unchanged
        ( , uint256 deadline0again, , ) = voting.polls(0);
        assertEq(deadline0again, 1000 + 5 * 60);
    }

    // ============ vote 组 ============

    // UT-005
    function testVoteHappy() public {
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        vm.prank(alice);
        voting.createPoll("Test", options, 10);

        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit Voted(0, alice, 1);

        voting.vote(0, 1);

        assertEq(voting.voteCounts(0, 1), 1);
        assertTrue(voting.hasVoted(0, alice));
    }

    // UT-006
    function testVoteMultipleVoters() public {
        string[] memory options = new string[](3);
        options[0] = "A";
        options[1] = "B";
        options[2] = "C";

        vm.prank(alice);
        voting.createPoll("Multi Voter", options, 10);

        vm.prank(alice);
        voting.vote(0, 0);

        vm.prank(bob);
        voting.vote(0, 1);

        vm.prank(charlie);
        voting.vote(0, 1);

        assertEq(voting.voteCounts(0, 0), 1);
        assertEq(voting.voteCounts(0, 1), 2);
        assertEq(voting.voteCounts(0, 2), 0);

        assertTrue(voting.hasVoted(0, alice));
        assertTrue(voting.hasVoted(0, bob));
        assertTrue(voting.hasVoted(0, charlie));
    }

    // UT-007
    function testVoteRevertsPollNotFound() public {
        vm.expectRevert(bytes("poll not found"));
        voting.vote(999, 0);
    }

    // UT-008
    function testVoteRevertsPollEnded() public {
        string[] memory options = new string[](2);
        options[0] = "A";
        options[1] = "B";

        vm.prank(alice);
        voting.createPoll("Ended", options, 10);

        ( , uint256 deadline, , ) = voting.polls(0);
        vm.warp(deadline + 1);

        vm.prank(alice);
        vm.expectRevert(bytes("poll ended"));
        voting.vote(0, 0);
    }

    // UT-008b
    function testVoteRevertsAtExactDeadline() public {
        string[] memory options = new string[](2);
        options[0] = "A";
        options[1] = "B";

        vm.prank(alice);
        voting.createPoll("Exact Deadline", options, 10);

        ( , uint256 deadline, , ) = voting.polls(0);
        vm.warp(deadline);

        vm.prank(alice);
        vm.expectRevert(bytes("poll ended"));
        voting.vote(0, 0);
    }

    // UT-008c
    function testVoteSuccessOneSecondBeforeDeadline() public {
        string[] memory options = new string[](2);
        options[0] = "A";
        options[1] = "B";

        vm.prank(alice);
        voting.createPoll("Last Second", options, 10);

        ( , uint256 deadline, , ) = voting.polls(0);
        vm.warp(deadline - 1);

        vm.prank(alice);
        voting.vote(0, 1);

        assertEq(voting.voteCounts(0, 1), 1);
        assertTrue(voting.hasVoted(0, alice));
    }

    // UT-009
    function testVoteRevertsAlreadyVoted() public {
        string[] memory options = new string[](3);
        options[0] = "A";
        options[1] = "B";
        options[2] = "C";

        vm.prank(alice);
        voting.createPoll("Already Voted", options, 10);

        vm.prank(alice);
        voting.vote(0, 0);

        // Try to vote again with a different option
        vm.prank(alice);
        vm.expectRevert(bytes("already voted"));
        voting.vote(0, 1);
    }

    // UT-010
    function testVoteRevertsInvalidOption() public {
        string[] memory options = new string[](3);
        options[0] = "A";
        options[1] = "B";
        options[2] = "C";

        vm.prank(alice);
        voting.createPoll("Invalid Option", options, 10);

        vm.prank(alice);
        vm.expectRevert(bytes("invalid option"));
        voting.vote(0, 3);
    }

    // UT-010b
    function testVoteRevertsFarOutOfBoundsOption() public {
        string[] memory options = new string[](2);
        options[0] = "A";
        options[1] = "B";

        vm.prank(alice);
        voting.createPoll("Far Out", options, 10);

        vm.prank(alice);
        vm.expectRevert(bytes("invalid option"));
        voting.vote(0, type(uint256).max);
    }

    // ============ getResult 组 ============

    // UT-011
    function testGetResultHappy() public {
        string[] memory options = new string[](3);
        options[0] = "A";
        options[1] = "B";
        options[2] = "C";

        vm.prank(alice);
        voting.createPoll("Result Test", options, 10);

        vm.prank(alice);
        voting.vote(0, 0);

        vm.prank(bob);
        voting.vote(0, 1);

        vm.prank(charlie);
        voting.vote(0, 1);

        uint256[] memory results = voting.getResult(0);
        assertEq(results.length, 3);
        assertEq(results[0], 1);
        assertEq(results[1], 2);
        assertEq(results[2], 0);
    }

    // UT-012
    function testGetResultRevertsPollNotFound() public {
        vm.expectRevert(bytes("poll not found"));
        voting.getResult(999);
    }

    // UT-013
    function testGetResultAllZeroWhenNoVotes() public {
        string[] memory options = new string[](5);
        options[0] = "A";
        options[1] = "B";
        options[2] = "C";
        options[3] = "D";
        options[4] = "E";

        vm.prank(alice);
        voting.createPoll("Zero Votes", options, 10);

        uint256[] memory results = voting.getResult(0);
        assertEq(results.length, 5);
        for (uint256 i = 0; i < 5; i++) {
            assertEq(results[i], 0);
        }
    }

    // UT-014
    function testGetResultLengthEqualsOptionCount() public {
        string[] memory options2 = new string[](2);
        options2[0] = "A";
        options2[1] = "B";

        string[] memory options6 = new string[](6);
        options6[0] = "A";
        options6[1] = "B";
        options6[2] = "C";
        options6[3] = "D";
        options6[4] = "E";
        options6[5] = "F";

        vm.prank(alice);
        voting.createPoll("2 Options", options2, 10);

        vm.prank(alice);
        voting.createPoll("6 Options", options6, 10);

        uint256[] memory results0 = voting.getResult(0);
        uint256[] memory results1 = voting.getResult(1);

        assertEq(results0.length, 2);
        assertEq(results1.length, 6);
    }

    // ============ 集成组 ============

    // UT-015
    function testFullLifecycle() public {
        string[] memory options = new string[](3);
        options[0] = "A";
        options[1] = "B";
        options[2] = "C";

        vm.prank(alice);
        voting.createPoll("Full Lifecycle", options, 10);

        // 4 people vote
        vm.prank(alice);
        voting.vote(0, 0);

        vm.prank(bob);
        voting.vote(0, 1);

        vm.prank(charlie);
        voting.vote(0, 2);

        vm.prank(dave);
        voting.vote(0, 1);

        // Verify results
        uint256[] memory results = voting.getResult(0);
        assertEq(results[0], 1);
        assertEq(results[1], 2);
        assertEq(results[2], 1);

        // Repeat vote reverts
        vm.prank(alice);
        vm.expectRevert(bytes("already voted"));
        voting.vote(0, 1);

        // Warp past deadline, vote reverts
        ( , uint256 deadline, , ) = voting.polls(0);
        vm.warp(deadline + 1);

        vm.prank(charlie);
        vm.expectRevert(bytes("poll ended"));
        voting.vote(0, 0);

        // getResult still works after deadline
        uint256[] memory resultsAfter = voting.getResult(0);
        assertEq(resultsAfter[0], 1);
        assertEq(resultsAfter[1], 2);
        assertEq(resultsAfter[2], 1);
    }

    // UT-016
    function testGetResultAfterDeadline() public {
        string[] memory options = new string[](2);
        options[0] = "Yes";
        options[1] = "No";

        vm.prank(alice);
        voting.createPoll("Deadline Result", options, 10);

        vm.prank(alice);
        voting.vote(0, 1);

        ( , uint256 deadline, , ) = voting.polls(0);

        // Warp far past deadline
        vm.warp(deadline + 10000);

        // getResult should still work without revert
        uint256[] memory results = voting.getResult(0);
        assertEq(results.length, 2);
        assertEq(results[0], 0);
        assertEq(results[1], 1);
    }
}
