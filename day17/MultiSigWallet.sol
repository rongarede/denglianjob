// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title MultiSigWallet
 * @dev A simple multi-signature wallet contract where multiple signers can confirm transactions,
 * and a transaction is executed only if the required number of confirmations is reached.
 */
contract MultiSigWallet {
    /// @notice Event emitted when a new transaction is submitted
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    /// @notice Event emitted when a transaction is confirmed
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Event emitted when a transaction is executed
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Event emitted when a transaction is revoked
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);

    // Struct representing a transaction proposal
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    // List of all transactions
    Transaction[] public transactions;

    // Mapping from txIndex => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    /**
     * @dev Initializes the contract by setting the list of owners and the number of required confirmations.
     * @param _owners The list of owners.
     * @param _numConfirmationsRequired The number of confirmations required for executing a transaction.
     */
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "Owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "Invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /**
     * @notice Submits a transaction proposal.
     * @dev Only wallet owners can call this function.
     * @param _to The recipient address.
     * @param _value The amount of ether to send.
     * @param _data The transaction data.
     */
    function submitTransaction(address _to, uint256 _value, bytes memory _data)
        public
        onlyOwner
    {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /**
     * @notice Confirms a transaction proposal.
     * @dev Only wallet owners can call this function.
     * @param _txIndex The index of the transaction to confirm.
     */
    function confirmTransaction(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /**
     * @notice Executes a confirmed transaction.
     * @dev Anyone can call this function.
     * @param _txIndex The index of the transaction to execute.
     */
    function executeTransaction(uint256 _txIndex)
        public
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Cannot execute transaction"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /**
     * @notice Revokes a confirmation for a transaction.
     * @dev Only wallet owners can call this function.
     * @param _txIndex The index of the transaction to revoke confirmation.
     */
    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        confirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /**
     * @dev Modifier to make a function callable only by the contract owners.
     */
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    /**
     * @dev Modifier to check if the transaction exists.
     * @param _txIndex The index of the transaction to check.
     */
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    /**
     * @dev Modifier to check if the transaction is not yet executed.
     * @param _txIndex The index of the transaction to check.
     */
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    /**
     * @dev Modifier to check if the transaction is already confirmed by the caller.
     * @param _txIndex The index of the transaction to check.
     */
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        _;
    }

    /**
     * @dev Modifier to check if the transaction is confirmed by the caller.
     * @param _txIndex The index of the transaction to check.
     */
    modifier confirmed(uint256 _txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");
        _;
    }

    // Fallback function to receive ether
    receive() external payable {}
}
