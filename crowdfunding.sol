//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding {
    mapping(address => uint) public contributors;
    address public admin;
    uint public numOfContributors;
    uint public minContribution;
    uint public deadline;  // timestamp
    uint public goal;
    uint public raisedAmount;
    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numOfVoters;
        mapping(address => bool) voters;
    }
    mapping(uint => Request) public spendingRequests;
    uint public numOfRequests;
    
    constructor(uint _goal, uint _deadline) {
        admin = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minContribution = 100 wei;
    }

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed.");
        require(msg.value >= minContribution, "Minimum contribution not met.");
        
        if (contributors[msg.sender] == 0) {
            numOfContributors++;
        }
        
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        emit ContributeEvent(msg.sender, msg.value);
    }
    
    receive() external payable {
        contribute();
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function getRefund() public {
        require(block.timestamp > deadline);
        require(raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);
        
        contributors[msg.sender] = 0;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }
    
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = spendingRequests[numOfRequests];
        numOfRequests++;
        
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numOfVoters = 0;
        
        emit CreateRequestEvent(_description, _recipient, _value);
        
    }
    
    function voteRequest(uint _requestNum) public {
        require(contributors[msg.sender] > 0, "You must be a contributor to vote.");
        
        Request storage thisRequest = spendingRequests[_requestNum];
        
        require(thisRequest.voters[msg.sender] == false, "You have already voted.");
        
        thisRequest.voters[msg.sender] = true;
        thisRequest.numOfVoters++;
    }
    
    function makePayment(uint _requestNum) public onlyAdmin {
        require(raisedAmount >= goal);
        Request storage thisRequest = spendingRequests[_requestNum];
        require(thisRequest.completed == false, "The request has been completed.");
        require(thisRequest.numOfVoters > numOfContributors / 2);
        
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}