pragma solidity 0.5.11;

import "./moloch/Moloch.sol";

contract Icarus {
    using SafeMath for uint256;
    // --- Constants ---
    string
        public constant MINION_ACTION_DETAILS = '{"isMinion": true, "kind": "Icarus", "title":"MINION", "description":"';
    uint256 public constant QUORUM = 20;
    uint256 public constant PADDING = 100;

    // --- State and data structures ---
    Moloch public moloch;
    Moloch public parentMoloch;
    address public molochApprovedToken;
    mapping(uint256 => Action) public actions; // proposalId => Action

    struct Action {
        uint256 value;
        address to;
        address proposer;
        bool executed;
        bytes data;
    }

    // --- Events ---
    event ActionProposed(uint256 proposalId, address proposer);
    event ActionCanceled(uint256 proposalId);
    event ActionExecuted(uint256 proposalId, address executor);

    // --- Modifiers ---
    modifier memberOnly() {
        require(isMember(msg.sender), "Minion::not member");
        _;
    }

    // --- Constructor ---
    constructor(address _moloch, address _parentMoloch) public {
        moloch = Moloch(_moloch);
        parentMoloch = Moloch(_parentMoloch);
        molochApprovedToken = moloch.depositToken();
    }

    // --- Fallback function ---
    function() external payable {}

    // withdraw funds from the moloch
    function doWithdraw(address _token, uint256 _amount) public {
        moloch.withdrawBalance(_token, _amount);
    }

    function doParentWithdraw(address _token, uint256 _amount) public {
        parentMoloch.withdrawBalance(_token, _amount);
        require(
            IERC20(_token).transferFrom(
                address(this),
                address(moloch),
                _amount
            ),
            "Minion::transfer to dao failed"
        );
    }

    function proposeAction(
        address _actionTo,
        uint256 _actionValue,
        bytes calldata _actionData,
        string calldata _description
    ) external memberOnly returns (uint256) {
        // can't call arbitrary functions on parent moloch, and no calls to
        // zero address allows us to check that Minion submitted
        // the proposal without getting the proposal struct from the moloch
        require(
            !(_actionTo == address(0) || _actionTo == address(moloch)),
            "Minion::invalid _actionTo"
        );

        string memory details = string(
            abi.encodePacked(MINION_ACTION_DETAILS, _description, '"}')
        );

        uint256 proposalId = moloch.submitProposal(
            address(this),
            0,
            0,
            0,
            molochApprovedToken,
            0,
            molochApprovedToken,
            details
        );

        Action memory action = Action({
            value: _actionValue,
            to: _actionTo,
            proposer: msg.sender,
            executed: false,
            data: _actionData
        });

        actions[proposalId] = action;

        emit ActionProposed(proposalId, msg.sender);
        return proposalId;
    }

    function cancelAction(uint256 _proposalId) external {
        Action memory action = actions[_proposalId];
        require(msg.sender == action.proposer, "Minion::not proposer");
        delete actions[_proposalId];
        emit ActionCanceled(_proposalId);
        moloch.cancelProposal(_proposalId);
    }

    function executeAction(uint256 _proposalId)
        external
        returns (bytes memory)
    {
        Action memory action = actions[_proposalId];
        bool isPassed = hasQuorum(_proposalId);

        // minion did not submit this proposal
        require(action.to != address(0), "Minion::invalid _proposalId");
        require(!action.executed, "Minion::action executed");
        require(
            address(this).balance >= action.value,
            "Minion::insufficient eth"
        );

        require(isPassed, "Minion::proposal quorum not met");

        // execute call
        actions[_proposalId].executed = true;
        (bool success, bytes memory retData) = action.to.call.value(
            action.value
        )(action.data);
        require(success, "Minion::call failure");
        emit ActionExecuted(_proposalId, msg.sender);
        return retData;
    }

    // --- View functions ---
    function isMember(address usr) public view returns (bool) {
        (, uint256 shares, , , , ) = moloch.members(usr);
        return shares > 0;
    }

    function hasQuorum(uint256 _proposalId) public view returns (bool) {
        // something like this to check is some quorum is met
        // if met execution can proceed before proposal is processed
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalShares = moloch.totalShares();

        (, , , , , , , , , , yesVotes, noVotes, , ) = moloch.proposals(_proposalId);

        uint256 quorum = yesVotes.mul(PADDING).div(totalShares);

        return quorum > QUORUM && yesVotes > noVotes;
    }
}
