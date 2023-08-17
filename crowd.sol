// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract CrowdFunding{

    //  Declaring all the variables and structs
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping (address=>bool) voters;
    }
    mapping (address=>uint) public contributors;
    mapping (uint=>Request) public requests;
    uint public numRequests;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    //  Constructor to initialize the variables
    constructor(uint _target,uint _deadline) {
        target=_target; //  A variable to store the minimum amount required to be funded
        deadline=block.timestamp+_deadline; //  To make the contract validd for a limited time frame
        minimumContribution=1 ether;    //  Store the minimum eligible payment in ethers
        manager=msg.sender; //  Stores the address of the manager
    }

    //  Function to check whether the current adress that is making the transaction is the manager or not. If it is the manager 
    //  then only we can assign itself to some other functions where the aaccess is limited to the manager only.
    modifier onlyManager(){
        require(msg.sender==manager,"You are not the manager");
        _;
    }

    //  To initialize the different variables of the structure. Storing more info about each transaction.
    function createRequests(string calldata _description,address payable _recipient,uint _value) public {
        Request storage newRequest=requests[numRequests];   //  Creating an instance of the requests structure
        numRequests++;  //  Increment the request and store the total number of requests at the end.
        newRequest.description=_description;//  To store the description of each request.
        newRequest.recipient=_recipient;//  To store the address of the recipient
        newRequest.value=_value;//  Stores the no of ethers the present request is contributing to the fund.
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }

    //  A function to handle the transaction of the contribution
    function contribution() public payable {
        require(block.timestamp<deadline,"Deadline has passed");//  Check if the deadline has passed
        require(msg.value>=minimumContribution,"Minimum contribution required is 0.001 ether");//   Check if the minimum ontribution is met

        //Check if the user has already contributed or not 
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

    //  Getting the balance of the fund
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }


    function refund() public{
        require(block.timestamp>deadline&& raisedAmount<target,"You are not eligible for refund");
        require(contributors[msg.sender]>0,"You are not a contributor");
        payable (msg.sender).transfer(contributors[msg.sender]);
    }


    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You are not a contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target,"Target is not reached");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters>noOfContributors/2,"Majority does not support the request");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}