// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenContract.sol";
import "./VotingContract.sol";

/**
 * @title ProposalContract
 * @dev Proposal management for VoteChain platform
 * @notice Handles proposal creation, lifecycle, and execution
 */
contract ProposalContract {
    // Events
    event ProposalCreated(bytes32 indexed proposalId, address indexed proposer, string title, uint256 timestamp);
    event ProposalUpdated(bytes32 indexed proposalId, string title, uint256 timestamp);
    event ProposalExecuted(bytes32 indexed proposalId, address indexed executor, uint256 timestamp);
    event ProposalCancelled(bytes32 indexed proposalId, address indexed canceller, uint256 timestamp);
    event ProposalStatusChanged(bytes32 indexed proposalId, uint256 oldStatus, uint256 newStatus);
    
    // Enums
    enum ProposalStatus { Draft, Active, PendingExecution, Executed, Cancelled, Expired }
    enum ProposalType { ParameterChange, Treasury, Upgrade, Governance, Other }
    
    // Structs
    struct Proposal {
        bytes32 id;
        address proposer;
        string title;
        string description;
        string ipfsHash; // IPFS hash for detailed proposal
        ProposalType proposalType;
        ProposalStatus status;
        uint256 createdAt;
        uint256 votingStartsAt;
        uint256 votingEndsAt;
        uint256 executionDelay;
        uint256 quorumRequired;
        uint256 approvalThreshold;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
        bytes32[] actions; // Array of action hashes
        bool executed;
        bool canExecute;
    }
    
    struct Action {
        bytes32 id;
        address target;
        uint256 value;
        bytes data;
        bool executed;
    }
    
    // State variables
    TokenContract public governanceToken;
    VotingContract public votingContract;
    
    mapping(bytes32 => Proposal) public proposals;
    mapping(bytes32 => Action) public actions;
    bytes32[] public proposalIds;
    
    // Governance parameters
    uint256 public constant MIN_PROPOSAL_THRESHOLD = 1000 * 10**18; // 1000 tokens
    uint256 public constant DEFAULT_QUORUM = 51; // 51%
    uint256 public constant DEFAULT_APPROVAL_THRESHOLD = 51; // 51%
    uint256 public constant DEFAULT_VOTING_PERIOD = 7 days;
    uint256 public constant DEFAULT_EXECUTION_DELAY = 1 days;
    uint256 public constant MAX_PROPOSAL_DESCRIPTION_LENGTH = 10000;
    
    address private owner;
    mapping(address => bool) public authorizedExecutors;
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Proposal: Only owner");
        _;
    }
    
    modifier onlyAuthorizedExecutor() {
        require(authorizedExecutors[msg.sender] || msg.sender == owner, "Proposal: Not authorized");
        _;
    }
    
    modifier onlyValidProposal(bytes32 proposalId) {
        require(proposals[proposalId].proposer != address(0), "Proposal: Invalid proposal");
        _;
    }
    
    modifier onlyProposer(bytes32 proposalId) {
        require(proposals[proposalId].proposer == msg.sender, "Proposal: Only proposer");
        _;
    }
    
    modifier onlyExecutable(bytes32 proposalId) {
        require(proposals[proposalId].status == ProposalStatus.PendingExecution, "Proposal: Not executable");
        require(block.timestamp >= proposals[proposalId].votingEndsAt + proposals[proposalId].executionDelay, "Proposal: Execution delay not met");
        require(proposals[proposalId].canExecute, "Proposal: Cannot execute");
        _;
    }
    
    constructor(address _tokenAddress, address _votingAddress) {
        owner = msg.sender;
        governanceToken = TokenContract(_tokenAddress);
        votingContract = VotingContract(_votingAddress);
        authorizedExecutors[owner] = true;
    }
    
    /**
     * @dev Creates a new proposal
     * @param title Proposal title
     * @param description Proposal description
     * @param ipfsHash IPFS hash for detailed proposal
     * @param proposalType Type of proposal
     * @param votingPeriod Voting period in seconds
     * @param quorumRequired Quorum percentage required
     * @param approvalThreshold Approval threshold percentage
     * @param targets Array of target addresses for actions
     * @param values Array of values for actions
     * @param data Array of data for actions
     * @return proposalId ID of the created proposal
     */
    function createProposal(
        string calldata title,
        string calldata description,
        string calldata ipfsHash,
        ProposalType proposalType,
        uint256 votingPeriod,
        uint256 quorumRequired,
        uint256 approvalThreshold,
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata data
    ) external returns (bytes32 proposalId) {
        require(governanceToken.getVotingPower(msg.sender) >= MIN_PROPOSAL_THRESHOLD, "Proposal: Insufficient voting power");
        require(bytes(title).length > 0, "Proposal: Title required");
        require(bytes(description).length > 0 && bytes(description).length <= MAX_PROPOSAL_DESCRIPTION_LENGTH, "Proposal: Invalid description length");
        require(targets.length == values.length && values.length == data.length, "Proposal: Mismatched action arrays");
        
        // Generate proposal ID
        proposalId = keccak256(abi.encodePacked(
            msg.sender,
            title,
            block.timestamp,
            block.chainid
        ));
        
        // Create proposal
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.title = title;
        proposal.description = description;
        proposal.ipfsHash = ipfsHash;
        proposal.proposalType = proposalType;
        proposal.status = ProposalStatus.Draft;
        proposal.createdAt = block.timestamp;
        proposal.votingStartsAt = block.timestamp;
        proposal.votingEndsAt = block.timestamp + votingPeriod;
        proposal.executionDelay = DEFAULT_EXECUTION_DELAY;
        proposal.quorumRequired = quorumRequired > 0 ? quorumRequired : DEFAULT_QUORUM;
        proposal.approvalThreshold = approvalThreshold > 0 ? approvalThreshold : DEFAULT_APPROVAL_THRESHOLD;
        
        // Create actions
        for (uint256 i = 0; i < targets.length; i++) {
            bytes32 actionId = keccak256(abi.encodePacked(proposalId, i, targets[i], values[i], data[i]));
            actions[actionId] = Action({
                id: actionId,
                target: targets[i],
                value: values[i],
                data: data[i],
                executed: false
            });
            proposal.actions.push(actionId);
        }
        
        proposalIds.push(proposalId);
        
        emit ProposalCreated(proposalId, msg.sender, title, block.timestamp);
        
        // Start voting period
        _startVoting(proposalId);
        
        return proposalId;
    }
    
    /**
     * @dev Updates a proposal (only in Draft status)
     * @param proposalId ID of the proposal
     * @param title New title
     * @param description New description
     * @param ipfsHash New IPFS hash
     */
    function updateProposal(
        bytes32 proposalId,
        string calldata title,
        string calldata description,
        string calldata ipfsHash
    ) external onlyProposer(proposalId) onlyValidProposal(proposalId) {
        require(proposals[proposalId].status == ProposalStatus.Draft, "Proposal: Cannot update active proposal");
        require(bytes(title).length > 0, "Proposal: Title required");
        require(bytes(description).length > 0 && bytes(description).length <= MAX_PROPOSAL_DESCRIPTION_LENGTH, "Proposal: Invalid description length");
        
        proposals[proposalId].title = title;
        proposals[proposalId].description = description;
        proposals[proposalId].ipfsHash = ipfsHash;
        
        emit ProposalUpdated(proposalId, title, block.timestamp);
    }
    
    /**
     * @dev Executes a proposal
     * @param proposalId ID of the proposal
     */
    function executeProposal(bytes32 proposalId) external onlyExecutable(proposalId) onlyAuthorizedExecutor {
        Proposal storage proposal = proposals[proposalId];
        
        // Execute all actions
        for (uint256 i = 0; i < proposal.actions.length; i++) {
            bytes32 actionId = proposal.actions[i];
            Action storage action = actions[actionId];
            
            if (!action.executed) {
                (bool success, ) = action.target.call{value: action.value}(action.data);
                require(success, "Proposal: Action execution failed");
                
                action.executed = true;
            }
        }
        
        proposal.status = ProposalStatus.Executed;
        proposal.executed = true;
        
        emit ProposalExecuted(proposalId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Cancels a proposal
     * @param proposalId ID of the proposal
     */
    function cancelProposal(bytes32 proposalId) external onlyProposer(proposalId) onlyValidProposal(proposalId) {
        require(proposals[proposalId].status == ProposalStatus.Draft || proposals[proposalId].status == ProposalStatus.Active, "Proposal: Cannot cancel");
        
        ProposalStatus oldStatus = proposals[proposalId].status;
        proposals[proposalId].status = ProposalStatus.Cancelled;
        
        emit ProposalCancelled(proposalId, msg.sender, block.timestamp);
        emit ProposalStatusChanged(proposalId, uint256(oldStatus), uint256(ProposalStatus.Cancelled));
    }
    
    /**
     * @dev Gets proposal information
     * @param proposalId ID of the proposal
     * @return Proposal details
     */
    function getProposal(bytes32 proposalId) external view onlyValidProposal(proposalId) returns (
        address proposer,
        string memory title,
        string memory description,
        string memory ipfsHash,
        ProposalType proposalType,
        ProposalStatus status,
        uint256 createdAt,
        uint256 votingStartsAt,
        uint256 votingEndsAt,
        uint256 quorumRequired,
        uint256 approvalThreshold,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes,
        bool executed,
        bool canExecute
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.ipfsHash,
            proposal.proposalType,
            proposal.status,
            proposal.createdAt,
            proposal.votingStartsAt,
            proposal.votingEndsAt,
            proposal.quorumRequired,
            proposal.approvalThreshold,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.abstainVotes,
            proposal.executed,
            proposal.canExecute
        );
    }
    
    /**
     * @dev Gets all proposal IDs
     * @return Array of proposal IDs
     */
    function getAllProposals() external view returns (bytes32[] memory) {
        return proposalIds;
    }
    
    /**
     * @dev Gets proposals by status
     * @param status Proposal status to filter by
     * @return Array of proposal IDs with specified status
     */
    function getProposalsByStatus(ProposalStatus status) external view returns (bytes32[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < proposalIds.length; i++) {
            if (proposals[proposalIds[i]].status == status) {
                count++;
            }
        }
        
        bytes32[] memory result = new bytes32[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < proposalIds.length; i++) {
            if (proposals[proposalIds[i]].status == status) {
                result[index] = proposalIds[i];
                index++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Checks if a proposal can be executed
     * @param proposalId ID of the proposal
     * @return True if executable
     */
    function isExecutable(bytes32 proposalId) external view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        return proposal.status == ProposalStatus.PendingExecution &&
               block.timestamp >= proposal.votingEndsAt + proposal.executionDelay &&
               proposal.canExecute;
    }
    
    /**
     * @dev Adds authorized executor
     * @param executor Address to add
     */
    function addAuthorizedExecutor(address executor) external onlyOwner {
        authorizedExecutors[executor] = true;
    }
    
    /**
     * @dev Removes authorized executor
     * @param executor Address to remove
     */
    function removeAuthorizedExecutor(address executor) external onlyOwner {
        authorizedExecutors[executor] = false;
    }
    
    /**
     * @dev Transfers ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    // Internal functions
    
    function _startVoting(bytes32 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        proposal.status = ProposalStatus.Active;
        
        // Start voting period in voting contract
        votingContract.startVotingPeriod(
            proposalId,
            proposal.votingEndsAt - proposal.votingStartsAt,
            proposal.quorumRequired
        );
    }
    
    /**
     * @dev Updates proposal vote counts (called by voting contract)
     * @param proposalId ID of the proposal
     * @param forVotes New for votes count
     * @param againstVotes New against votes count
     * @param abstainVotes New abstain votes count
     */
    function updateVoteCounts(
        bytes32 proposalId,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes
    ) external {
        require(msg.sender == address(votingContract), "Proposal: Only voting contract");
        
        Proposal storage proposal = proposals[proposalId];
        proposal.forVotes = forVotes;
        proposal.againstVotes = againstVotes;
        proposal.abstainVotes = abstainVotes;
        
        // Check if proposal can be executed
        _checkExecution(proposalId);
    }
    
    function _checkExecution(bytes32 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.status != ProposalStatus.Active) {
            return;
        }
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        uint256 totalSupply = governanceToken.totalSupply();
        
        // Check quorum
        bool quorumMet = (totalVotes * 100) / totalSupply >= proposal.quorumRequired;
        
        // Check approval threshold
        bool approvalMet = false;
        if (totalVotes > 0) {
            approvalMet = (proposal.forVotes * 100) / totalVotes >= proposal.approvalThreshold;
        }
        
        if (quorumMet && approvalMet) {
            proposal.status = ProposalStatus.PendingExecution;
            proposal.canExecute = true;
        } else if (block.timestamp >= proposal.votingEndsAt) {
            proposal.status = ProposalStatus.Expired;
        }
    }
}
