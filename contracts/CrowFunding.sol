// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract CrowFunding {
    mapping(address => uint) contributors;
    address public admin;
    uint public numberOfContributors;
    uint public minimumContribution;
    uint public deadLine;
    uint public goal;
    uint public raiseAmount;

    struct Request {
        string description;
        uint value;
        address payable recipient;
        uint numberOfVoters;
        mapping(address => bool) voters;
        bool completed;
    }

    mapping(uint => Request) public requests;
    uint public numberOfRequest;

    constructor(uint _goal, uint _deadLine) {
        goal = _goal;
        deadLine = block.timestamp + _deadLine;
        admin = msg.sender;
        minimumContribution = 0.1 ether;
    }

    event ControbuteEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    function contribute() public payable {
        require(block.timestamp <= deadLine, "DeadLine has passed");
        require(msg.value >= minimumContribution, "Minimum Contribution not met");
        if(contributors[msg.sender] == 0) {
            numberOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raiseAmount += msg.value;

        emit ControbuteEvent(msg.sender, msg.value);
    }

    receive() payable external {
        contribute();
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(raiseAmount > goal && block.timestamp > deadLine);
        require(contributors[msg.sender] > 0);
        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numberOfRequest];
        numberOfRequest++;
        newRequest.completed = false;
        newRequest.description = _description;
        newRequest.numberOfVoters = 0;
        newRequest.recipient = _recipient;
        newRequest.value = _value; 

        emit CreateRequestEvent(_description, _recipient, _value);
    }

    function voteRequest(uint _requestNumber) public {
        require(contributors[msg.sender] > 0, "You must be a contributor to vote");
        Request storage thisRequest = requests[_requestNumber];

        require(thisRequest.voters[msg.sender] == false, "You have already voted");
        thisRequest.voters[msg.sender] == true;
        thisRequest.numberOfVoters++;
    }

    function makePayment(uint _requestNumber) public payable onlyAdmin {
        require(raiseAmount > goal);
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.completed == false, "Request has been completed");
        require(thisRequest.numberOfVoters > numberOfContributors / 2);

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed == true;

        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}