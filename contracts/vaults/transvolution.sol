pragma solidity 0.5.17;

import "./Minion.sol";

contract Transmutation {
    using SafeMath for uint256;

    string public constant TRANSMUTATION_DETAILS = '{"isTransmutation": true, "title":"TRANSMUTATION", "description":"';
    uint256 constant MAX_UINT = 2**256 - 1;

    Moloch public moloch;
    Minion public minion;
    IERC20 public token;
    address public molochApprovedToken; // deposit token (main payment funds)
    mapping (uint256 => Proposal) public proposals; // proposalId => Action
    uint256 exchangeRate;

    struct Proposal {
        address proposer;
    }

    event Proposed(uint256 proposalId, address proposer);

    constructor(address payable _minion, address _token) public {
        minion = Minion(_minion); // The minion we're interacting with.
        moloch = minion.moloch(); // The Moloch we're interacting with.
        molochApprovedToken = moloch.depositToken(); // Single token for deposits when sponsoring. first token in the Moloch token whitelist.
        token = IERC20(_token); // The token that Minion can use for transmutation (ex: DAI).
        token.approve(address(minion), MAX_UINT); // This approves Minion to transfer tokens anywhere.
        token.approve(address(moloch), MAX_UINT); //  This is needed for tribute. The moloch has to transfer tokens from this contract to the bank.
    }

    // This lets the proposor cancel before the proposal is sponsored, probably a mistake or whatever.
    // Without this it would have to be ignored forever or sponsored and voted down.
    function doCancel(uint256 _proposalId) public {
        Proposal memory proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "Transmutation::Must be proposer");
        moloch.cancelProposal(_proposalId);
    }

    // Only minion (dao proposal) can change rates.
    // This is done via a DAO proposal (via the ABI input field on the Minion UI).
    function setRate(uint256 rate) public {
        require(msg.sender == address(minion),"Only the minion");
        exchangeRate = rate;
    }

    function submitProposal(address _applicant, uint256 _tributeOffered, uint256 _sharesRequested, string memory _details) public returns (uint256) {
        // `address _applicant` doesn't have to be the person calling the function.
        // Could be any address. This is so that we could use multisigs.
        // Could also be used if a DAO member calls the function to simultaniously move funds from guildbank and give a new member shares.

        // Only DAO members can request transmutation.
        // This is to limit spam, but could be removed.
        uint256 shares;
        (,shares,,,,) = moloch.members(msg.sender);
        require(shares > 0, "Transmutation::Not a current dao member");

        // Tribute to send from Minion to Moloch
        // Check to make sure Minion has enough
        // ??? from this contract not the moloch, tribute has to come from msg.sender ???
        require(_tributeOffered < token.balanceOf(address(this)), "Transmutation::Not enough tokens"); // `this` here refers to the Minion, not the person calling this function right?

        // This is where the proposal description goes.
        // More of a flag for the front end so we can easily know its a special proposal type.
        string memory details = string(abi.encodePacked(TRANSMUTATION_DETAILS, _details, '"}')); // Is this where the proposal description goes?

        uint256 proposalId = moloch.submitProposal(
            _applicant, // The address to receive shares. Can be anyone (doesn't have to be the address calling this function).
            _sharesRequested, // shares requested
            0, // loot requested
            _tributeOffered, // this contract offereing tribute to the dao (ex: transfering DAI from this contract)
            address(token), // address(token) is DAI or whatever is set in the contructor.
            0, // was _paymentRequested
            molochApprovedToken,  // The DAOs deposit token. Could be the same as `address(token)`. If they always will be then you should use it here instead of molochApprovedToken
            details
        );

        emit Proposed(proposalId, msg.sender);
        return proposalId;
    }

    function() external payable { }
}
