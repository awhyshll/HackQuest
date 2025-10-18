// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title SimpleVoting
/// @notice Small on-chain voting contract: owner creates proposals, opens/closes voting, anyone can vote once per proposal.
/// @dev Designed for EVM-compatible chains (e.g., Flow EVM testnet). Keep gas and storage minimal.
contract SimpleVoting {
    address public owner;
    bool public votingOpen;

    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount;
        bool exists;
    }

    // proposalId => Proposal
    mapping(uint256 => Proposal) private proposals;
    // proposalId => voter => hasVoted
    mapping(uint256 => mapping(address => bool)) private hasVoted;

    uint256 public proposalCount;

    event ProposalCreated(uint256 indexed id, string description);
    event VotingOpened();
    event VotingClosed();
    event Voted(uint256 indexed proposalId, address indexed voter);
    event ProposalRemoved(uint256 indexed id);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier whenOpen() {
        require(votingOpen, "voting is not open");
        _;
    }

    modifier whenClosed() {
        require(!votingOpen, "action allowed only when voting is closed");
        _;
    }

    constructor() {
        owner = msg.sender;
        votingOpen = false;
    }

    /// @notice Owner adds a new proposal (only while voting is closed)
    /// @param _description Short description for the proposal
    function addProposal(string calldata _description) external onlyOwner whenClosed {
        require(bytes(_description).length > 0, "description required");
        uint256 id = ++proposalCount;
        proposals[id] = Proposal({ id: id, description: _description, voteCount: 0, exists: true });
        emit ProposalCreated(id, _description);
    }

    /// @notice Owner can remove a proposal (only while voting is closed)
    /// @param _id proposal id
    function removeProposal(uint256 _id) external onlyOwner whenClosed {
        require(proposals[_id].exists, "proposal not found");
        delete proposals[_id];
        emit ProposalRemoved(_id);
    }

    /// @notice Owner opens voting. After opening, proposals cannot be added/removed.
    function openVoting() external onlyOwner whenClosed {
        require(proposalCount > 0, "no proposals");
        votingOpen = true;
        emit VotingOpened();
    }

    /// @notice Owner closes voting.
    function closeVoting() external onlyOwner whenOpen {
        votingOpen = false;
        emit VotingClosed();
    }

    /// @notice Vote for a proposal (one vote per address per proposal) while voting is open
    /// @param _proposalId id of proposal
    function vote(uint256 _proposalId) external whenOpen {
        require(proposals[_proposalId].exists, "proposal not found");
        require(!hasVoted[_proposalId][msg.sender], "already voted for this proposal");

        hasVoted[_proposalId][msg.sender] = true;
        proposals[_proposalId].voteCount += 1;

        emit Voted(_proposalId, msg.sender);
    }

    /// @notice Returns proposal details
    /// @param _proposalId id
    function getProposal(uint256 _proposalId)
        external
        view
        returns (uint256 id, string memory description, uint256 voteCount, bool exists)
    {
        Proposal memory p = proposals[_proposalId];
        return (p.id, p.description, p.voteCount, p.exists);
    }

    /// @notice Returns whether an address has voted for a specific proposal
    function didVote(uint256 _proposalId, address _voter) external view returns (bool) {
        return hasVoted[_proposalId][_voter];
    }

    /// @notice Returns the winning proposal id(s). If tie, returns the smallest id among highest (useful on-chain summary).
    /// @dev This loops through proposals; gas cost grows with number of proposals. OK for small lists.
    function winningProposal() external view returns (uint256 winningId, uint256 winningVotes) {
        uint256 bestId = 0;
        uint256 bestVotes = 0;
        for (uint256 i = 1; i <= proposalCount; ++i) {
            if (!proposals[i].exists) {
                continue;
            }
            uint256 v = proposals[i].voteCount;
            if (v > bestVotes) {
                bestVotes = v;
                bestId = i;
            }
        }
        return (bestId, bestVotes);
    }

    /// @notice Owner can transfer ownership
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "invalid owner");
        owner = _newOwner;
    }

    /// @notice Recover any accidentally sent ETH (contract should not hold ETH). Only owner.
    function recoverEther(address payable _to) external onlyOwner whenClosed {
        uint256 bal = address(this).balance;
        require(bal > 0, "no balance");
        _to.transfer(bal);
    }

    // Fallback/receive to allow accidental ether retrieval
    receive() external payable {}
    fallback() external payable {}
}
