// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//can Add Transaction and threshold for TX
// can add signer and weight
// can add new transaction Type
// get a transaction count
// get all transactions
// get signer count
// get signer using their address
// get tx using their index
// transaction Threshold
//Submit tx if threshold is meant

//// revock signed tx
//get all transaction

contract NewMultiSig  {
    event NewDeposit(address indexed sender, uint amount);
    event NewWithdrawal(address indexed sender, uint amount);
    event NewTransfer(address indexed receiver, uint amount);

    //Mapping for transactions List
    mapping(string => uint) public transactionTypeList;
    mapping(address => uint) private AccountWeightList;

    mapping(uint => TransactionObj) listOfAllTransactions;

    // mapping(address => uint) public owners;
    address private Owners;

    //Modifier to check if the sender has the right weight to call functions

    struct TransactionObj{
        address to;
        uint amount;
        string transactionType;
        bool executed;
        uint totalNumbersOfSig;
    }
    struct SignerList{
        address id;
        uint sigWeight;
    }
    event TransactionSubmitted(address _sender, uint _amt, address _receiver);
    event SignerAdded(address _signerAdd, uint _signerWeight);
    event TransactionAdded(address _adder, uint _amount, address _to);
    event TransactionSigned(address _signer, uint _txIndex, uint _signerWeight, uint _requiredThreshold);
    event NewTypeOfTransactionAdded(address _sender, string _txName, uint _requiredThreshold);
    event revockSignature(address _sender, uint _weightRemove);

    mapping(address => SignerList) AllSigners;
    mapping(uint => mapping(address => bool)) isSigned; //if Tx is signed
    mapping(address => bool) addressIsASigner; // Need to get the address specific index numder to work perfectly
    uint public signerCounter;

    // TransactionObj[] private listOfAllTransactions;
    //Counter for Transaction
    uint public txCounter;

    modifier isOwner{
        require(msg.sender == Owners, "Only Contract owner can call this enpoint");
        _;
    }

    modifier isTxSigned(uint _txID){
        require(!isSigned[_txID][msg.sender], "Address already Signed Tx");
        _;
    }
    modifier isAddrASigner(){
        require(addressIsASigner[msg.sender], "Not a Signer");
        _;
    }

    modifier TxNotExecuted(uint _txIndex){
        require(!listOfAllTransactions[_txIndex].executed, "transaction already submitted");
        _;
    }
    modifier hasAddrSignedTx(uint _txIndex){
        require(isSigned[_txIndex][msg.sender], "You have not signed this transaction");
        _;
    }
    modifier isTransactionAvailable(uint _txIndex){
        require(txCounter >= _txIndex && txCounter > 0, "No Valid Transaction");
        _;
    }
    //Check if we have a valid transaction


    // Contructor takes numbers of address, their weight. We use a pre-defined threshold for all type of transactions
    // The threshold is the number of signatures required to approve a transaction

    constructor(){
        Owners = msg.sender;
        transactionTypeList["deposit"] = 0;
        transactionTypeList["withdrawal"] = 80;
        transactionTypeList["transfer"] = 60;
        txCounter =0;
        signerCounter =0;
    }

    // Need to Restrict the add signer method to only owner
    // allowing smart contrcat to recieve eth


     receive() external payable {}


// ===============================================================================
                // TRANSACTIONS
// ===============================================================================


    // Add a new Transaction for signing
    function addTransaction(address _to, uint _amt, string memory _transactionType ) public isAddrASigner {

        // modifier to automatically check transaction type
        listOfAllTransactions[txCounter] = TransactionObj({
            to: _to,
            amount:_amt,
            executed: false,
            transactionType: _transactionType,
            totalNumbersOfSig:0

        });

        txCounter++;
        emit TransactionAdded(msg.sender, _amt, _to);
    }

    //Method to check if transaction exist and if yes, it returns it threshold
    // add modiers to check if transaction exist in our list of tx, if not we return an error
    function getTxWeight(string memory _txName) public view returns (uint){
        return transactionTypeList[_txName];
    }


    // return a tuple of all availabe transaction and their details including signature
    function getAllTranactions() public view returns (TransactionObj[] memory){
      TransactionObj[] memory transactionobj = new TransactionObj[](txCounter);
      for (uint i = 0; i < txCounter; i++) {
          TransactionObj storage txobjs = listOfAllTransactions[i];
          transactionobj[i] = txobjs;
      }
      return transactionobj;
  }
    //This get transaction by it index number
    function getTxByID(uint _txID) public view returns(TransactionObj memory) {
        return listOfAllTransactions[_txID];
    }

    //This adds a specific new type of transaction type and also the weight threshold required to execute
    function addTxWeight(string memory _name, uint _weight) public {
        transactionTypeList[_name]=_weight;
        emit NewTypeOfTransactionAdded(msg.sender, _name, _weight);
    }

    function revockSignerSig(uint _txIndex) public isAddrASigner hasAddrSignedTx(_txIndex){
        TransactionObj storage _tx = listOfAllTransactions[_txIndex];
        uint addressWeight = AllSigners[msg.sender].sigWeight;
        uint newTxvalue = _tx.totalNumbersOfSig - addressWeight;
        _tx.totalNumbersOfSig = newTxvalue;
        isSigned[_txIndex][msg.sender] = false;

        emit revockSignature(msg.sender, addressWeight);
    }

// ===============================================================================
            // SIGNERS
// ===============================================================================

      //This add a specific address and their weight
    function addSignerWithWeight(address _signerAdd, uint _weight) public isOwner {
        AllSigners[_signerAdd] = SignerList({ id:_signerAdd, sigWeight: _weight});
        addressIsASigner[_signerAdd] = true;
        signerCounter++;
        emit SignerAdded(_signerAdd, _weight);
    }


    //get signer by their index and return their address and weight
    function getSignerByAddress(address _address )public view returns (SignerList memory){
        return AllSigners[_address];
    }


    //this should all address to sign transaction
    function signTransaction(uint _txId) public isAddrASigner isTransactionAvailable(_txId) isTxSigned (_txId) {
        TransactionObj storage txToSign = listOfAllTransactions[_txId];
        address _signerAddress = msg.sender;
        SignerList memory _signer = AllSigners[_signerAddress];
        txToSign.totalNumbersOfSig += _signer.sigWeight;
        isSigned[_txId][msg.sender] = true;
        uint txrequiredThreashold = transactionTypeList[txToSign.transactionType];

        emit TransactionSigned(msg.sender, _txId, _signer.sigWeight, txrequiredThreashold);

    }

    // //this should all users to submit transaction if weidgt meets the threshold of the transaction type
    function submitTransaction(uint _txIndex) public isAddrASigner isTransactionAvailable(_txIndex) TxNotExecuted(_txIndex) {
        TransactionObj storage _txToSubmit = listOfAllTransactions[_txIndex];
        uint _txThreshold = transactionTypeList[_txToSubmit.transactionType];
        require(_txToSubmit.totalNumbersOfSig >= _txThreshold, "need more signer to sign transaction before execution");
        address payable recipientAddres = payable(_txToSubmit.to);
        recipientAddres.transfer(_txToSubmit.amount);
        _txToSubmit.executed = true;
        emit TransactionSubmitted(address(this), _txToSubmit.amount, recipientAddres);
    }
}


