pragma solidity 0.5.17;

import "../minion/Minion.sol";

contract Transmutation {

    string public constant TRANSMUTATION_DETAILS = '{"isTransmutation": true, "title":"TRANSMUTATION", "description":"';
    uint256 constant MAX_UINT = 2**256 - 1;
    
    Moloch public moloch;
    Minion public minion;
    IERC20 public token;
    address public molochApprovedToken; // deposit token (main payment funds)
    mapping (uint256 => Proposal) public proposals; // proposalId => Action
    uinit256 exchangeRate;

    struct Proposal {
        address proposer;
    }

    event Proposed(uint256 proposalId, address proposer);

    constructor(address _minion, address _token, unit256 initialRate) public {
        minion = Minion(_minion);
        moloch = minion.moloch();s
        molochApprovedToken = moloch.depositToken();
        token = IERC20(_token);
        token.approve(address(minion), MAX_UINT);
        token.approve(address(moloch), MAX_UINT);
    }

    function doCancel(uint256 _proposalId) public {
        Proposal memory proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "Minion::Must be proposer");
        moloch.cancelProposal(_proposalId);
    }
    
    function setRate(uint256 rate){
        require(msg.send == address(minion),"")
        echangeRate = rate;
    }
    
    function submitProposal(
        uint256 _tributeOffered,
        uint256 _paymentRequested,
        string memory _details
        ) 
        public
        returns (uint256)
        {
        uint256 shares;
        (,shares,,,,) = moloch.members(msg.sender);
        require(shares > 0, "Minion::Not a current dao member");
        
        string memory details = string(abi.encodePacked(TRANSMUTATION_DETAILS, _details, '"}'));
        
        // could set _tributeOffered based on a rate
        
        uint256 proposalId = moloch.submitProposal(
            msg.sender,
            0,
            0,
            _tributeOffered,
            address(token),
            _paymentRequested,
            molochApprovedToken,
            details
        );
        
        emit Proposed(proposalId, msg.sender);
        return proposalId;
    }


    function() external payable { }
}