// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IVoting.sol";

contract Voting is IVoting, Ownable{
    
    uint private winningProposalId;
    
    WorkflowStatus private currentStatus;
    
    mapping(address => Voter) private voters;
    mapping(uint => Proposal) private proposals;
    uint private proposalsCounter;
    
    function registerVoter(address voterAddress) public onlyOwner{
        require(voterAddress != address(0), "Voting: registration not allowed for the zero address");
        require(currentStatus == WorkflowStatus.RegisteringVoters, "Voting : registration not allowed in the current status");

        voters[voterAddress] = Voter(true, false, 0);
        emit VoterRegistered(voterAddress);
    }
    
    function startProposalsRegistration() public onlyOwner{
        require(currentStatus == WorkflowStatus.RegisteringVoters, "Voting: could not start registration in the current status");
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit ProposalsRegistrationStarted();
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, currentStatus);
    }
    
    function submitProposal(string memory proposalDescription) public{
        require(voters[msg.sender].isRegistered, "Voting: voter is not registered");
        require(bytes(proposalDescription).length > 0, "Voting: proposal description can not be empty");
        proposalsCounter++;
        proposals[proposalsCounter] = Proposal(proposalDescription, 0);
        emit ProposalRegistered(proposalsCounter);
    }
    
    function stopProposalsRegistration() public onlyOwner{
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "Voting: could not start registration in the current status");
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit ProposalsRegistrationEnded();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, currentStatus);
    }
    
    function startVotingSession() public onlyOwner{
        require(currentStatus == WorkflowStatus.ProposalsRegistrationEnded, "Voting: could not start voting session in the current status");
        currentStatus = WorkflowStatus.VotingSessionStarted;
        emit VotingSessionStarted();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, currentStatus);
    }
    
    function voteForProposal(uint proposalId) public{
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "Voting: vote is not allowed in the current status");
        require(voters[msg.sender].isRegistered, "Voting: voter is not registered");
        require(!voters[msg.sender].hasVoted, "Voting: voter has already voted");
        require(bytes(proposals[proposalId].description).length > 0, "Voting: Unknown proposal id");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
        proposals[proposalId].voteCount++;
        
        emit Voted(msg.sender, proposalId);
    }
    
    function stopVotingSession() public onlyOwner{
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "Voting: could not stop voting session in the current status");
        currentStatus = WorkflowStatus.VotingSessionEnded;
        emit VotingSessionEnded();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, currentStatus);
    }
    
    function getVotedProposal(address voterAddress) public view returns(uint, string memory){
        require(voters[voterAddress].hasVoted, "Voting: voter has not voted yet");
        return (voters[voterAddress].votedProposalId, proposals[voters[voterAddress].votedProposalId].description);
    }
    
    function computeWinningProposal() public onlyOwner{
        require(currentStatus == WorkflowStatus.VotingSessionEnded, "Voting: could not compute the winning Proposal in the current status");
        winningProposalId = 1;
        for(uint i = 2; i <= proposalsCounter; i++){
            if(proposals[winningProposalId].voteCount < proposals[i].voteCount){
                winningProposalId = i;
            }
        }
        currentStatus = WorkflowStatus.VotesTallied;
        emit VotesTallied();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, currentStatus);
    }
    
    function getWinningProposal() public view returns(Proposal memory){
        require(currentStatus == WorkflowStatus.VotesTallied, "Voting: could not get the winning proposal id in the current status");
        return proposals[winningProposalId];
    }
}