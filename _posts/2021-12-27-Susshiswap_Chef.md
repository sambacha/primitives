---
created: 2021-12-26T17:37:10 (UTC -08:00)
tags: [analysis,sushiswap,protocol]
source: https://chowdera.com/2021/07/20210726071642995z.html
author: 
---

# Analysis of sushiswap protocol - 文章整合

> ## Excerpt
> Protocol Brief  SushiSwap It's a bifurcation from Uniswap Decentrali

---
#### **Protocol Brief**

SushiSwap is a bifurcation from UniswapV2, which itself can trace back to Bancor Protocol.
 It continues in the trading model Uniswap The core design of ——AMM( Auto market makers ) Model , But with Uniswap The difference is SushiSwap Added economic reward model ,SushiSwap The transaction fee is 0.3%, among 0.25% Direct distribution to liquidity providers ,0.05% Buy into SUSHI And assigned to Sushi Token holders (Uniswap It is through the switch mode to decide whether to 0.05% The service charge to the developer team ),Sushi Reserved for each distribution 10% Provide future development iteration and safety audit for the project .


> Sushiswap GitHub
 > https://github.com/sushiswap/sushiswap

#### **vcs structure**

SushiSwap The source code structure of the protocol is as follows , In the later source code analysis stage, we mainly focus on time-locked contracts and SushiSwap Analyze the content of the document ,UniswapV2 The agreement is no longer in-depth , For more information, please refer to the previous UniswapV2 Protocol analysis article ：

#### **Source code analysis**

Next, we will SushiSwap Analysis of key documents;

-   SushiToken： Token contract , With voting function
-   MasterChef： take LPsTokens Deposit in SUSHI fram
-   SushiMaker： Collect transaction fees , Convert to SUSHI And send it to SushiBar
-   SushiBar： mortgage SUSHI To get more SUSHI
-   Migrator： hold MasterChef LP from Uniswap Migrate to SushiSwap
-   GovernorAlpha+Timelock： come from Compound The governance function of
-   UniswapV2：UniswapV2 contract , Minor modifications were made to migrate the contract

##### **Timelock**

Timelock The contract will affect any updates executed by the smart contract 48 Hour time lock , Exit in function timelock after , It can be used 5 In multiple team signatures 3 One to execute , The picture below is SushiSwap In contract timelock The recorded information of ：

https://app.sushi.com/governance

The following code is SushiSwap Official timelock Source code

```solidity

// SPDX-License-Identifier: MIT

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Ctrl+f for XXX to see all the modifications.

// XXX: pragma solidity ^0.5.16;
pragma solidity 0.6.12;

// XXX: import "./SafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Timelock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE\_PERIOD = 14 days;
    uint public constant MINIMUM\_DELAY = 2 days;
    uint public constant MAXIMUM\_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;
    bool public admin\_initialized;

    mapping (bytes32 => bool) public queuedTransactions;


    constructor(address admin\_, uint delay\_) public {
        require(delay\_ >= MINIMUM\_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay\_ <= MAXIMUM\_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

        admin = admin\_;
        delay = delay\_;
        admin\_initialized = false;
    }

    // XXX: function() external payable { }
    receive() external payable { }

    function setDelay(uint delay\_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay\_ >= MINIMUM\_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay\_ <= MAXIMUM\_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay\_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin\_) public {
        // allows one time setting of admin for deployment purposes
        if (admin\_initialized) {
            require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        } else {
            require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
            admin\_initialized = true;
        }
        pendingAdmin = pendingAdmin\_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions\[txHash\] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions\[txHash\] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions\[txHash\], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE\_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions\[txHash\] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}
```

At the beginning of the contract, a series of events are defined ：

```solidity
// to update Admin
event NewAdmin(address indexed newAdmin);
// newly added Admin To Admin Preparation queue 
event NewPendingAdmin(address indexed newPendingAdmin);
// New delay time 
event NewDelay(uint indexed newDelay);
// Cancel the deal 
event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
// Execute the transaction 
event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
// Add transaction pair transaction queue 
event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
```

```solidity
Then the minimum delay time, maximum delay time and grace period are defined ：

uint public constant GRACE\_PERIOD = 14 days;    // Grace period :14 God 
uint public constant MINIMUM\_DELAY = 2 days;    // Minimum delay time 
uint public constant MAXIMUM\_DELAY = 30 days;   // Maximum delay time 

Then declare the global variables that will be used later ：

address public admin;             //admin Address 
address public pendingAdmin;    //pendingAdmin Address 
uint public delay;          // Delay time 
bool public admin\_initialized;    //admin Is the address initialized 
mapping (bytes32 => bool) public queuedTransactions; // Use mapping Store transaction queue , The key value pair is bytes32=>bool( Transaction bytes and whether in queue Boolean )

Then initialize in the constructor , requirement delay The delay is between the minimum delay and the maximum delay , After initialization admin Address , And will admin\_initialized Set to false:

    constructor(address admin\_, uint delay\_) public {
        require(delay\_ >= MINIMUM\_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay\_ <= MAXIMUM\_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

        admin = admin\_;
        delay = delay\_;
        admin\_initialized = false;
    }
```


After that receive The function is used to accept the transfer of tokens from the external account address and contract address to the current contract address ：

    // XXX: function() external payable { }
    receive() external payable { }

setDelay Function to update the delay , The function requires the caller of the function to be the current contract address itself , At the same time, the delay is required to be between the shortest delay and the maximum delay , After through emit Triggering event ：

    function setDelay(uint delay\_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay\_ >= MINIMUM\_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay\_ <= MAXIMUM\_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay\_;

        emit NewDelay(delay);
    }

acceptAdmin Function to update admin Address , This function requires the function caller to be admin Address in queue , Then ask to update the current admin And will admin The address in was removed , After through emit Triggering event ：

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

setPendingAdmin The function sets the in the queue admin Address , First of all, I will check admin\_initialized Is it true( In the constructor admin Address initialized , however admin\_initialized Still for false, Nothing new ), If false entering else, Then check whether the current function caller is admin Address , If so, update admin\_initialized, Set it to true, Then update pendingAdmin, When called the second time setPendingAdmin when , At this time admin\_initialized Already been true, Therefore, the caller will be required to be the current contract address , That's why SushiSwap Officially " Administrative rights have been given to time lock (timelock) contract " Why ：

    function setPendingAdmin(address pendingAdmin\_) public {
        // allows one time setting of admin for deployment purposes
        if (admin\_initialized) {
            require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        } else {
            require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
            admin\_initialized = true;
        }
        pendingAdmin = pendingAdmin\_;

        emit NewPendingAdmin(pendingAdmin);
    }

queueTransaction Used to add a transaction to the transaction queue , The function first retrieves whether the function caller is admin Address , Then retrieve whether the delay requirements are met , Then calculate the transaction hash, Then add the transaction to the transaction queue , And pass emit Triggering event ：

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions\[txHash\] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

cancelTransaction The function cancels a transaction in the transaction queue , First, it will retrieve whether the caller of the current function is a contract admin Address , Then calculate a transaction hash, Then remove the transaction from the transaction queue , After through emit Triggering event ：

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions\[txHash\] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

executeTransaction Function to execute a transaction , This function first retrieves whether the caller of the current function is admin Address , Then calculate a transaction hash, Then retrieve whether the delay condition is met , Then remove the transaction from the transaction queue , And then through call Call execute transaction , Finally through emit Triggering event ：

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions\[txHash\], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE\_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions\[txHash\] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

getBlockTimestamp The function is simple , Just get the timestamp of the current block ：

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

##### **SushiToken**

SushiToken It's a token contract , With voting function , The following is the official source code ：

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// SushiToken with Governance.
contract SushiToken is ERC20("SushiToken", "SUSHI"), Ownable {
    /// @notice Creates \`\_amount\` token to \`\_to\`. Must only be called by the owner (MasterChef).
    function mint(address \_to, uint256 \_amount) public onlyOwner {
        \_mint(\_to, \_amount);
        \_moveDelegates(address(0), \_delegates\[\_to\], \_amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @notice A record of each accounts delegate
    mapping (address => address) internal \_delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN\_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION\_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /\*\*
     \* @notice Delegate votes from \`msg.sender\` to \`delegatee\`
     \* @param delegator The address to get delegatee for
     \*/
    function delegates(address delegator)
        external
        view
        returns (address)
{
        return \_delegates\[delegator\];
    }

   /\*\*
    \* @notice Delegate votes from \`msg.sender\` to \`delegatee\`
    \* @param delegatee The address to delegate votes to
    \*/
    function delegate(address delegatee) external {
        return \_delegate(msg.sender, delegatee);
    }

    /\*\*
     \* @notice Delegates votes from signatory to \`delegatee\`
     \* @param delegatee The address to delegate votes to
     \* @param nonce The contract state required to match the signature
     \* @param expiry The time at which to expire the signature
     \* @param v The recovery byte of the signature
     \* @param r Half of the ECDSA signature pair
     \* @param s Half of the ECDSA signature pair
     \*/
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
{
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN\_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION\_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\\x19\\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SUSHI::delegateBySig: invalid signature");
        require(nonce == nonces\[signatory\]++, "SUSHI::delegateBySig: invalid nonce");
        require(now <= expiry, "SUSHI::delegateBySig: signature expired");
        return \_delegate(signatory, delegatee);
    }

    /\*\*
     \* @notice Gets the current votes balance for \`account\`
     \* @param account The address to get votes balance
     \* @return The number of current votes for \`account\`
     \*/
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
{
        uint32 nCheckpoints = numCheckpoints\[account\];
        return nCheckpoints > 0 ? checkpoints\[account\]\[nCheckpoints - 1\].votes : 0;
    }

    /\*\*
     \* @notice Determine the prior number of votes for an account as of a block number
     \* @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     \* @param account The address of the account to check
     \* @param blockNumber The block number to get the vote balance at
     \* @return The number of votes the account had as of the given block
     \*/
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
{
        require(blockNumber < block.number, "SUSHI::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints\[account\];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints\[account\]\[nCheckpoints - 1\].fromBlock <= blockNumber) {
            return checkpoints\[account\]\[nCheckpoints - 1\].votes;
        }

        // Next check implicit zero balance
        if (checkpoints\[account\]\[0\].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints\[account\]\[center\];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints\[account\]\[lower\].votes;
    }

    function \_delegate(address delegator, address delegatee)
        internal
{
        address currentDelegate = \_delegates\[delegator\];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SUSHIs (not scaled);
        \_delegates\[delegator\] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        \_moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function \_moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints\[srcRep\];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints\[srcRep\]\[srcRepNum - 1\].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                \_writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints\[dstRep\];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints\[dstRep\]\[dstRepNum - 1\].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                \_writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function \_writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
{
        uint32 blockNumber = safe32(block.number, "SUSHI::\_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints\[delegatee\]\[nCheckpoints - 1\].fromBlock == blockNumber) {
            checkpoints\[delegatee\]\[nCheckpoints - 1\].votes = newVotes;
        } else {
            checkpoints\[delegatee\]\[nCheckpoints\] = Checkpoint(blockNumber, newVotes);
            numCheckpoints\[delegatee\] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2\*\*32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

This function inherits from ERC20( This is a novel way of writing , Use it directly ERC-20 Initializes the current contract with the constructor of ) and Ownable:

contract SushiToken is ERC20("SushiToken", "SUSHI"), Ownable {

After that mint The function is used to issue additional tokens , This function needs to pass two parameters ：

-   to： Address to accept new tokens
-   \_amount： Number of new tokens

The function consists of onlyOwner Modifier modification , Contract required owner call , Then call UniswapV2 Of mint Function to perform coinage operations ：

    function mint(address \_to, uint256 \_amount) public onlyOwner {
        \_mint(\_to, \_amount);
        \_moveDelegates(address(0), \_delegates\[\_to\], \_amount);
    }

 // Ownable.sol
    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        \_;
    }

// UniswapV2ERC20.sol
    function \_mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf\[to\] = balanceOf\[to\].add(value);
        emit Transfer(address(0), to, value);
    }

Then call \_moveDelegates Transfer entrustment , Here, we take the parameters passed in before as an example for analysis, and go directly to the last if In the sentence , Then according to dstRep To retrieve the inspection site of the account ( A check site that marks the number of votes for a particular block ), When the number of inspection sites of the account is greater than 0, Retrieve the number of votes from the last checkpoint and assign it to srcRepOld, If there are no detection points, it is set to 0, Then use the original number of votes plus the number of assets to be transferred , As new votes ( It can also be said that additional issuance token Related to the number of votes ,1 token representative 1 ticket ), Then call \_writeCheckpoint Update check site ：

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }
    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

  function \_moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints\[srcRep\];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints\[srcRep\]\[srcRepNum - 1\].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                \_writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints\[dstRep\];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints\[dstRep\]\[dstRepNum - 1\].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                \_writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

\_writeCheckpoint The code is as follows , The parameters here are described as follows ：

-   delegatee： Accept token Address
-   nCheckpoints： Number of original checkpoints
-   oldVotes： Number of old votes
-   newVotes： Number of new votes

Then get the current number of blocks , Then check whether the number of original checkpoints is greater than 0, Accept token Of the previous checkpoint corresponding to the address fromBlock Is it consistent with the current number of blocks , Update accepted if consistent token Voting of the previous checkpoint corresponding to the address , Otherwise, the update is accepted token The current check site of the address votes , At the same time, add the number of inspection sites 1, After through emit Triggering event , In general, coinage is accompanied by the recording and distribution of votes ：

    function \_writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
)
        internal
{
        uint32 blockNumber = safe32(block.number, "SUSHI::\_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints\[delegatee\]\[nCheckpoints - 1\].fromBlock == blockNumber) {
            checkpoints\[delegatee\]\[nCheckpoints - 1\].votes = newVotes;
        } else {
            checkpoints\[delegatee\]\[nCheckpoints\] = Checkpoint(blockNumber, newVotes);
            numCheckpoints\[delegatee\] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2\*\*32, errorMessage);
        return uint32(n);
    }

Here are some global variables defined , Some of them have been introduced to ：

    /// @notice A record of votes checkpoints for each account, by index
  //  Voting checkpoint records for each account listed by index 
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
  //   Checkpoints per account 
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN\_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION\_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    //  Signature / Verify the status record of the signature 
    mapping (address => uint) public nonces;

Then there are two events ：

     /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

After that delegates The function is used to vote for the function caller delegator：

    /\*\*
     \* @notice Delegate votes from \`msg.sender\` to \`delegatee\`
     \* @param delegator The address to get delegatee for
     \*/
    function delegates(address delegator)
        external
        view
        returns (address)
{
        return \_delegates\[delegator\];
    }

delegatee The function is also used to deliver the ticket of the function caller to the specified address , Different from the above, this function calls \_moveDelegates Used to transfer delegates ：

   /\*\*
    \* @notice Delegate votes from \`msg.sender\` to \`delegatee\`
    \* @param delegatee The address to delegate votes to
    \*/
    function delegate(address delegatee) external {
        return \_delegate(msg.sender, delegatee);
    }
    function \_delegate(address delegator, address delegatee)
        internal
{
        address currentDelegate = \_delegates\[delegator\];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SUSHIs (not scaled);
        \_delegates\[delegator\] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        \_moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

From the signatory to the authorized person's representative to vote ：

-   delegatee： Address to which the vote will be delegated
-   nonce： Contract status required to match signature
-   expiry： Time when the expired signature expires
-   v： Signed recovery bytes
-   r：ECDSA Signature pair r Half
-   s： yes ECDSA Half of the signature pair

    /\*\*
     \* @notice Delegates votes from signatory to \`delegatee\`
     \* @param delegatee The address to delegate votes to
     \* @param nonce The contract state required to match the signature
     \* @param expiry The time at which to expire the signature
     \* @param v The recovery byte of the signature
     \* @param r Half of the ECDSA signature pair
     \* @param s Half of the ECDSA signature pair
     \*/
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
{
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN\_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION\_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\\x19\\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SUSHI::delegateBySig: invalid signature");
        require(nonce == nonces\[signatory\]++, "SUSHI::delegateBySig: invalid nonce");
        require(now <= expiry, "SUSHI::delegateBySig: signature expired");
        return \_delegate(signatory, delegatee);
    }

getCurrentVotes Used to get the current vote ：

    /\*\*
     \* @notice Gets the current votes balance for \`account\`
     \* @param account The address to get votes balance
     \* @return The number of current votes for \`account\`
     \*/
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
{
        uint32 nCheckpoints = numCheckpoints\[account\];
        return nCheckpoints > 0 ? checkpoints\[account\]\[nCheckpoints - 1\].votes : 0;
    }

getPriorVotes Function to determine the number of priority votes for an account starting with a block number ：

    /\*\*
     \* @notice Determine the prior number of votes for an account as of a block number
     \* @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     \* @param account The address of the account to check
     \* @param blockNumber The block number to get the vote balance at
     \* @return The number of votes the account had as of the given block
     \*/
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
{
        require(blockNumber < block.number, "SUSHI::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints\[account\];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints\[account\]\[nCheckpoints - 1\].fromBlock <= blockNumber) {
            return checkpoints\[account\]\[nCheckpoints - 1\].votes;
        }

        // Next check implicit zero balance
        if (checkpoints\[account\]\[0\].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints\[account\]\[center\];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints\[account\]\[lower\].votes;
    }

getChainId The function retrieves the current getChainId：

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

##### **MasterChef**

MasterChef The main purpose of the contract is to LPsTokens Deposit in SUSHI fram, The following is the official contract source code ：

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SushiToken.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to SushiSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount \* pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's \`accSushiPerShare\` (and \`lastRewardBlock\`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's \`amount\` gets updated.
        //   4. User's \`rewardDebt\` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }
    // The SUSHI TOKEN!
    SushiToken public sushi;
    // Dev address.
    address public devaddr;
    // Block number when bonus SUSHI period ends.
    uint256 public bonusEndBlock;
    // SUSHI tokens created per block.
    uint256 public sushiPerBlock;
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS\_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo\[\] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        SushiToken \_sushi,
        address \_devaddr,
        uint256 \_sushiPerBlock,
        uint256 \_startBlock,
        uint256 \_bonusEndBlock
) public {
        sushi = \_sushi;
        devaddr = \_devaddr;
        sushiPerBlock = \_sushiPerBlock;
        bonusEndBlock = \_bonusEndBlock;
        startBlock = \_startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 \_allocPoint,
        IERC20 \_lpToken,
        bool \_withUpdate
) public onlyOwner {
        if (\_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(\_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: \_lpToken,
                allocPoint: \_allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSushiPerShare: 0
            })
        );
    }

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(
        uint256 \_pid,
        uint256 \_allocPoint,
        bool \_withUpdate
) public onlyOwner {
        if (\_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo\[\_pid\].allocPoint).add(
            \_allocPoint
        );
        poolInfo\[\_pid\].allocPoint = \_allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef \_migrator) public onlyOwner {
        migrator = \_migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 \_pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo\[\_pid\];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given \_from to \_to block.
    function getMultiplier(uint256 \_from, uint256 \_to)
        public
        view
        returns (uint256)
{
        if (\_to <= bonusEndBlock) {
            return \_to.sub(\_from).mul(BONUS\_MULTIPLIER);
        } else if (\_from >= bonusEndBlock) {
            return \_to.sub(\_from);
        } else {
            return
                bonusEndBlock.sub(\_from).mul(BONUS\_MULTIPLIER).add(
                    \_to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending SUSHIs on frontend.
    function pendingSushi(uint256 \_pid, address \_user)
        external
        view
        returns (uint256)
{
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[\_user\];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward =
                multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accSushiPerShare = accSushiPerShare.add(
                sushiReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 \_pid) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sushiReward =
            multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        sushi.mint(devaddr, sushiReward.div(10));
        sushi.mint(address(this), sushiReward);
        pool.accSushiPerShare = pool.accSushiPerShare.add(
            sushiReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 \_pid, uint256 \_amount) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[msg.sender\];
        updatePool(\_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeSushiTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            \_amount
        );
        user.amount = user.amount.add(\_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        emit Deposit(msg.sender, \_pid, \_amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 \_pid, uint256 \_amount) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[msg.sender\];
        require(user.amount >= \_amount, "withdraw: not good");
        updatePool(\_pid);
        uint256 pending =
            user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeSushiTransfer(msg.sender, pending);
        user.amount = user.amount.sub(\_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), \_amount);
        emit Withdraw(msg.sender, \_pid, \_amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 \_pid) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[msg.sender\];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, \_pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeSushiTransfer(address \_to, uint256 \_amount) internal {
        uint256 sushiBal = sushi.balanceOf(address(this));
        if (\_amount > sushiBal) {
            sushi.transfer(\_to, sushiBal);
        } else {
            sushi.transfer(\_to, \_amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address \_devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = \_devaddr;
    }
}

The structure defined here UserInfo Used to store user information ：

-   amount： User owned LP tokens The number of
-   rewardDebt： A previous liability when the user calculates the reward

there rewardDebt It can also be understood as liabilities , Because when everyone mortgages, the rewards in the pool may have begun to be distributed or accumulated , namely accSushiPerShare The value is increasing and changing , After each user is mortgaged, he can't give all the previously accumulated rewards to him , Because he can't generate rewards before he mortgages , So there is a debt , Deduct the reward generated by the whole pool before he mortgages from the total reward , From his mortgage , This is also the source of user reward calculation ：

 pending reward = (user.amount \* pool.accSushiPerShare) - user.rewardDebt

At the same time, it can be seen from the annotation information that the user is accessing LP tokens when , In the pool accSushiPerShare、lastRewardBlock、rewardDebt And other information is changing ：

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount \* pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's \`accSushiPerShare\` (and \`lastRewardBlock\`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's \`amount\` gets updated.
        //   4. User's \`rewardDebt\` gets updated.
    }

Structure defined here PoolInfo Used to store pool information ：

-   lpToken：LP Token Contract address
-   allocPoint： Pools are allocated from a single block SUSHIs The weight of
-   lastRewardBlock：SUSHIs The number of the last block distributed
-   accSushiPerShare： When calculating mortgage mining, single LP The number of corresponding rewards that a token can get

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }

After that, the global variables used later are declared ：

    // The SUSHI TOKEN!
    SushiToken public sushi;            //SUSHI Token Contract address 
    // Dev address.
    address public devaddr;              // Production environment address 
    // Block number when bonus SUSHI period ends.
    uint256 public bonusEndBlock;          // Reward SUSHI End time zone block number 
    // SUSHI tokens created per block.
    uint256 public sushiPerBlock;          // A block can be generated SUSHI Number 
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS\_MULTIPLIER = 10;  // In the early sushi Reward double 
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;          //migrator Contract address 
    // Info of each pool.
    PoolInfo\[\] public poolInfo;            // An array used to store ore pool information 
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;   // User's mortgage LP Tokens Information about 
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;            // Total distribution weight ( It must be the sum of the assigned weights of all pools )
    // The block number when SUSHI mining starts.
    uint256 public startBlock;            // The momentum block where mining began 

The sum of defines related events ：

     // Storage 
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  // extract 
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
   // Emergency withdrawal 
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
);

The subsequent constructor initializes ：

    constructor(
        SushiToken \_sushi,
        address \_devaddr,
        uint256 \_sushiPerBlock,
        uint256 \_startBlock,
        uint256 \_bonusEndBlock
    ) public {
        sushi = \_sushi;
        devaddr = \_devaddr;
        sushiPerBlock = \_sushiPerBlock;
        bonusEndBlock = \_bonusEndBlock;
        startBlock = \_startBlock;
    }

poolLength Used to return the current number of pools ：

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

add Function to add a pool , This function can only be used by the contract owner call , And three parameters need to be passed ：

-   \_allocPoint： Assign weights (\_allocPoint/totalAllocPoint Assign... To a single block of the current pool SUSHIs Total of )
-   \_lpToken：LP Tokens Contract address
-   \_withUpdate： Update pool

We'll check here first \_withUpdate Boolean value , If true Then update the pool once , If false, Then retrieve the current number of last reward blocks , Then update the total allocated points , After that, the newly created pool information is stored ：

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 \_allocPoint,
        IERC20 \_lpToken,
        bool \_withUpdate
) public onlyOwner {
        if (\_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(\_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: \_lpToken,
                allocPoint: \_allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSushiPerShare: 0
            })
        );
    }

set Function to update the in the pool SUSHI Assign points , This function can only be used by the contract owner call , Here you need to pass three parameters ：

-   \_pid： Pool's ID Sequence
-   \_allocPoint： Assign weights (\_allocPoint/totalAllocPoint Assign... To a single block of the current pool SUSHIs Total of )
-   \_withUpdate： Whether to update

Then check whether it is updated , If true Then update the pool once , If false, Through pid Retrieve the allocated points of the corresponding pool , The assigned points are updated later ：

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(
        uint256 \_pid,
        uint256 \_allocPoint,
        bool \_withUpdate
) public onlyOwner {
        if (\_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo\[\_pid\].allocPoint).add(
            \_allocPoint
        );
        poolInfo\[\_pid\].allocPoint = \_allocPoint;
    }

setMigrator Functions can only be defined by contract owner call , Used for setting up migrate The address of the contract ：

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef \_migrator) public onlyOwner {
        migrator = \_migrator;
    }

migrate The function is used to LP token Move to another one LP In contract , It will be checked here first migrator Whether the address is empty , Then according to pid Parameter to retrieve the corresponding pool information , Later retrieval LpToken Contract address , Query after LpToken Held by the current contract address in the contract LP Token Number , Then call LpToken The contract safeApprove The function returns the current contract address LP Tokens Operation authority authorized to migrator Contract address , Then call migrator The contract migrator Function , Then check LpToken The account corresponding to the current contract address in the contract Lp tokens Is it equal to the current newLpToken Held by the current contract account address in the contract LP Tokens Number , Finally, update the in the pool information lpToken Address

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 \_pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo\[\_pid\];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

Now we're right migrate Of migrate The method is analyzed , Look at the specific migration process , This will be passed in from above first lpToken The address of the contract is orig The value of the parameter , The relevant inspection here will not be repeated ( among chef、notBeforeBlock、oldFactory Connect to Migrator The contract is initialized in the constructor , No discussion ), Then use token0 And token1 Store old LpToken Address information of transaction pair in , Then according to token0 and token1 Retrieve whether the corresponding transaction pair exists at present , If not, create a new one , Then use lp Storage LpToken Of function callers in contracts Lp Tokens Number , If at this time lp by 0, Then return directly pair, If lp Not for 0, Will lp Assign a value to desiredLiquidity, Then call LpToken In the contract transferFrom Function transfer lp To LpToken In the contract address , Then call LpToken Contract address burn The function extracts the corresponding two assets by burning liquidity tokens , And reduce the liquidity of transaction pairs accordingly , Finally, by calling the of the current transaction pair mint Function when the user provides mobility ( Provide a certain proportion of two ERC-20 Token to transaction pair ) Add liquidity tokens to liquidity providers and finally complete LP Migration , It should be noted that it must comply with UniswapV2 agreement ：

// Migrator

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";


contract Migrator {
    address public chef;
    address public oldFactory;
    IUniswapV2Factory public factory;
    uint256 public notBeforeBlock;
    uint256 public desiredLiquidity = uint256(-1);

    constructor(
        address \_chef,
        address \_oldFactory,
        IUniswapV2Factory \_factory,
        uint256 \_notBeforeBlock
    ) public {
        chef = \_chef;
        oldFactory = \_oldFactory;
        factory = \_factory;
        notBeforeBlock = \_notBeforeBlock;
    }

    function migrate(IUniswapV2Pair orig) public returns (IUniswapV2Pair) {
        require(msg.sender == chef, "not from master chef");
        require(block.number >= notBeforeBlock, "too early to migrate");
        require(orig.factory() == oldFactory, "not from old factory");
        address token0 = orig.token0();
        address token1 = orig.token1();
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        if (pair == IUniswapV2Pair(address(0))) {
            pair = IUniswapV2Pair(factory.createPair(token0, token1));
        }
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return pair;
        desiredLiquidity = lp;
        orig.transferFrom(msg.sender, address(orig), lp);
        orig.burn(address(pair));
        pair.mint(msg.sender);
        desiredLiquidity = uint256(-1);
        return pair;
    }
}

getMultiplier Function to obtain the reward multiplier , First of all, I will check to Is the address less than SUSHI Number of blocks after a round , If yes, calculate to and from Difference between , Then multiply by BONUS\_MULTIPLIER And back to , If to Greater than ,SUSHI Number of blocks after a round , Then check from Is it greater than SUSHI Number of blocks after a round , If yes, calculate to And from Difference between , Then return , If form Less than SUSHI Number of blocks after a round ,to Greater than SUSHI Number of blocks after a round , The calculation from And to Difference between , Then multiply by BONUS\_MULTIPLIER, And then add to subtract SUSHI Number of blocks after a round ：

    // Return reward multiplier over the given \_from to \_to block.
    function getMultiplier(uint256 \_from, uint256 \_to)
        public
        view
        returns (uint256)
{
        if (\_to <= bonusEndBlock) {
            return \_to.sub(\_from).mul(BONUS\_MULTIPLIER);
        } else if (\_from >= bonusEndBlock) {
            return \_to.sub(\_from);
        } else {
            return
                bonusEndBlock.sub(\_from).mul(BONUS\_MULTIPLIER).add(
                    \_to.sub(bonusEndBlock)
                );
        }
    }

pendingSushi The function is used to retrieve information from a queue SUSHI, The function will first pid To retrieve the corresponding pool , Then according to pid and user Retrieve the user information in the corresponding pool ( Structure information storage ), Then retrieve the data in the pool accSushiPerShare, Then use lpSupply Storage LpToken What is the current contract address in the contract Lp Total amount , Then check whether the current number of blocks is greater than the last reward block in the pool and lpSupply Is it 0, Before calling getMultiplier To calculate the reward multiplier , Then multiply the reward product by a block SUSHI Tokens Number , Then multiply by the assigned weight of the pool ( Pool allocation points divided by total allocation points ), Then update accSushiPerShare( Use accSushiPerShare add sushiReward Then multiply by 1e12 And divide by lpSupply), Then use the information held by the user LpTokens Quantity times accSushiPerShare Then divide by 1e12, Then subtract user liabilities ：

    // View function to see pending SUSHIs on frontend.
    function pendingSushi(uint256 \_pid, address \_user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[\_user\];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward =
                multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accSushiPerShare = accSushiPerShare.add(
                sushiReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

massUpdatePools Used to update the reward pool , Here, first get the number of reward pools , Then update from the first reward pool , The update method is called directly updatePool function ：

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

updatePool Function is the specific implementation of updating the reward pool , First of all, according to pid To retrieve the corresponding pool information , Then check whether the current block number is less than the latest reward block in the pool , If yes, direct return, If it is larger than the latest reward block, retrieve LpTokens The corresponding to the current contract address in the contract address LP Total amount , If LP A total of 0, Then update the last reward block to the current number of blocks , If LP Not for 0, Call getMultiplier To calculate the reward multiplier , Calculated after sushiReward, Then call sushi The contract mint Function issuance sushiReward.div(10) Quantity of quantity SUSHI, This is also what the article said at the beginning "Sushi Reserved for each distribution 10% Provide future development iteration and safety audit for the project ", Then issue additional to the current contract address sushiReward In quantity SUSHI, The last update accSushiPerShare, And the most recent reward block .

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 \_pid) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sushiReward =
            multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        sushi.mint(devaddr, sushiReward.div(10));
        sushi.mint(address(this), sushiReward);
        pool.accSushiPerShare = pool.accSushiPerShare.add(
            sushiReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

deposit The function is used to LP token Pledge to MasterChef For convenience SUSHI Distribute , The function will first pid Retrieve the corresponding pool , Then according to pid and msg.sender Retrieve information about users in the pool , Then call updatePool Update the pool once , Then retrieve the information held by the user LP token Is it greater than 0, If it is greater than 0 Then calculate once pending Rewards during , The specific calculation method is to use the... Held by the user LP token Number times the number in the pool accSushiPerShare, Then divide by 1e12, And minus the user's incentive liabilities , Then call safeSushiTransfer send out pending In quantity SUSHI To msg.sender, Call later lpToken The contract safeTransferFrom Function will msg.sender In the address \_amount In quantity LpToken Send to current contract , Then update the information held by the user LpToken Total amount , And the user's debt reward , After through emit Triggering event ：

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 \_pid, uint256 \_amount) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[msg.sender\];
        updatePool(\_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeSushiTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            \_amount
        );
        user.amount = user.amount.add(\_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        emit Deposit(msg.sender, \_pid, \_amount);
    }

withdraw The function is used from MasterChef Extract from Lp Token, The function will first pid To retrieve the corresponding pool , Then according to pid and msg.sender To retrieve the corresponding user Information , Then check user Held by LP tokens Is it greater than the value to extract Lp tokens Number , Then update the pool , Then calculate once pending( Rewards obtained during queue , Because in withdraw and deposits There may be other users accessing , Lead to accSushiPerShare Wait for the change , There will also be rewards at this stage ), Then call safeSushiTransfer Send corresponding quantity SUSHI To msg.sender, Then update the information held by the user LPTokens Number , The incentive liability is then updated , Then call lpToken The contract safeTransfer Function first msg.sender The address to send amout In quantity LP tokens, Then call emit Triggering event .

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 \_pid, uint256 \_amount) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[msg.sender\];
        require(user.amount >= \_amount, "withdraw: not good");
        updatePool(\_pid);
        uint256 pending =
            user.amount.mul(pool.accSushiPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeSushiTransfer(msg.sender, pending);
        user.amount = user.amount.sub(\_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), \_amount);
        emit Withdraw(msg.sender, \_pid, \_amount);
    }

emergencyWithdraw For emergency withdrawal , First of all, according to pid Retrieve the corresponding pool , Then according to pid as well as msg.sender Address to retrieve user information , Then call LpToken The contract Safetransfer Function first msg.sender The address to send user.amount In quantity LP tokens, After through emit Triggering event , And update the information held by the user LP tokens Number of awards and liabilities .

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 \_pid) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[msg.sender\];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, \_pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

safeSushiTransfer A function is a simple SUSHI Transfer function , No more details here ：

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeSushiTransfer(address \_to, uint256 \_amount) internal {
        uint256 sushiBal = sushi.balanceOf(address(this));
        if (\_amount > sushiBal) {
            sushi.transfer(\_to, sushiBal);
        } else {
            sushi.transfer(\_to, \_amount);
        }
    }

##### **MasterChefV2**

MasterChefV2 And MasterChef similar , I won't go into that here ~

##### **Migrator**

Migrator The role of the contract is mainly to support UniswapV2 Implementation in the pool of protocols LP The migration operation of , Because this part of the code has been carefully explained before , I won't go into that here , If there are questions , You can turn it forward , Here is Migrator Source code ：

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";


contract Migrator {
    address public chef;
    address public oldFactory;
    IUniswapV2Factory public factory;
    uint256 public notBeforeBlock;
    uint256 public desiredLiquidity = uint256(-1);

    constructor(
        address \_chef,
        address \_oldFactory,
        IUniswapV2Factory \_factory,
        uint256 \_notBeforeBlock
    ) public {
        chef = \_chef;
        oldFactory = \_oldFactory;
        factory = \_factory;
        notBeforeBlock = \_notBeforeBlock;
    }

    function migrate(IUniswapV2Pair orig) public returns (IUniswapV2Pair) {
        require(msg.sender == chef, "not from master chef");
        require(block.number >= notBeforeBlock, "too early to migrate");
        require(orig.factory() == oldFactory, "not from old factory");
        address token0 = orig.token0();
        address token1 = orig.token1();
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        if (pair == IUniswapV2Pair(address(0))) {
            pair = IUniswapV2Pair(factory.createPair(token0, token1));
        }
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return pair;
        desiredLiquidity = lp;
        orig.transferFrom(msg.sender, address(orig), lp);
        orig.burn(address(pair));
        pair.mint(msg.sender);
        desiredLiquidity = uint256(-1);
        return pair;
    }
}

**Ownable**

Ownerable The contract is a supplementary extension contract , Mainly involves owner Initialization and owner Transfer of authority, etc , It's simpler , No more details here , Here is the source code ：

// SPDX-License-Identifier: MIT
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract OwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract Ownable is OwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address \_pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == \_pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, \_pendingOwner);
        owner = \_pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        \_;
    }
}

##### **SushiBar**

SushiBar The main function of the contract is mortgage SUSHI To get more SUSHI, Users can mortgage first Sushi, Then get xSushi In return , Then put it in xSushi In the pool , When the user SushiSwap When trading on the exchange , Will charge 0.3％ The cost of , Of this fee 0.05％ With LP Add as token to SushiBar In the pool , When the award contract is invoked ( At least once a day ), all LP Tokens will be Sushi At the price of ( stay SushiSwap Exchange On ), Then the newly purchased SUSHI Prorated to in pool xSushi holder , It means their xSushi Now the value is higher . at present , Until withdrawal , You can see the increased amount , It was originally 1 individual SUSHI= 1 individual xSushi, But like LP Like tokens ,xSushi The price of will change over time , It depends on how much is in the pool SUSHI Reward , The following is the official source code ：

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// SushiBar is the coolest bar in town. You come in with some Sushi, and leave with more! The longer you stay, the more Sushi you get.
//
// This contract handles swapping to and from xSushi, SushiSwap's staking token.
contract SushiBar is ERC20("SushiBar", "xSUSHI"){
    using SafeMath for uint256;
    IERC20 public sushi;

    // Define the Sushi token contract
    constructor(IERC20 \_sushi) public {
        sushi = \_sushi;
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi
    function enter(uint256 \_amount) public {
        // Gets the amount of Sushi locked in the contract
        uint256 totalSushi = sushi.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSushi == 0) {
            \_mint(msg.sender, \_amount);
        } 
        // Calculate and mint the amount of xSushi the Sushi is worth. The ratio will change overtime, as xSushi is burned/minted and Sushi deposited + gained from fees / withdrawn.
        else {
            uint256 what = \_amount.mul(totalShares).div(totalSushi);
            \_mint(msg.sender, what);
        }
        // Lock the Sushi in the contract
        sushi.transferFrom(msg.sender, address(this), \_amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Sushi and burns xSushi
    function leave(uint256 \_share) public {
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Sushi the xSushi is worth
        uint256 what = \_share.mul(sushi.balanceOf(address(this))).div(totalShares);
        \_burn(msg.sender, \_share);
        sushi.transfer(msg.sender, what);
    }
}

Current contract inherited from ERC20 contract , And an initialization operation is carried out

contract SushiBar is ERC20("SushiBar", "xSUSHI"){

Then initialize... In the constructor SUSHI The address of the contract

    // Define the Sushi token contract
    constructor(IERC20 \_sushi) public {
        sushi = \_sushi;
    }

there enter Function for locking sushi And casting Xsushi, Here, we will first check the... In the current contract sushi Total amount , Then calculate once xSushi Total amount , If l The total amount of any of the above two is 0, Call \_mint Functions in accordance with the 1:1 Proportional coinage , If neither is 0 Then calculate the additional shares to be issued Xsushi Total amount , And call mint Additional issuance Xsushi, Then call sushi Of transferfrom Function to inject... Into the current contract address sushi：

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi
    function enter(uint256 \_amount) public {
        // Gets the amount of Sushi locked in the contract
        uint256 totalSushi = sushi.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSushi == 0) {
            \_mint(msg.sender, \_amount);
        } 
        // Calculate and mint the amount of xSushi the Sushi is worth. The ratio will change overtime, as xSushi is burned/minted and Sushi deposited + gained from fees / withdrawn.
        else {
            uint256 what = \_amount.mul(totalShares).div(totalSushi);
            \_mint(msg.sender, what);
        }
        // Lock the Sushi in the contract
        sushi.transferFrom(msg.sender, address(this), \_amount);
    }

there leave Function to unlock and extract Sushi And destroy Xsushi, The function is completely opposite to the function above , Here we first calculate xSushi Total amount , Then calculate the current xSushi How much can it be worth Sushi, And then destroy xSushi And extract Sushi

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Sushi and burns xSushi
    function leave(uint256 \_share) public {
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Sushi the xSushi is worth
        uint256 what = \_share.mul(sushi.balanceOf(address(this))).div(totalShares);
        \_burn(msg.sender, \_share);
        sushi.transfer(msg.sender, what);
    }

##### **SushiMaker**

SushiMaker Role conversion of contract Token by SUSHI And send it to SushiBar, The official source code is as follows ：

// SPDX-License-Identifier: MIT

// P1 - P3: OK
pragma solidity 0.6.12;
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./uniswapv2/interfaces/IUniswapV2ERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";

import "./Ownable.sol";

// SushiMaker is MasterChef's left hand and kinda a wizard. He can cook up Sushi from pretty much anything!
// This contract handles "serving up" rewards for xSushi holders by trading tokens collected from fees for Sushi.

// T1 - T4: OK
contract SushiMaker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // V1 - V5: OK
    IUniswapV2Factory public immutable factory;
    //0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
    // V1 - V5: OK
    address public immutable bar;
    //0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272
    // V1 - V5: OK
    address private immutable sushi;
    //0x6B3595068778DD592e39A122f4f5a5cF09C90fE2
    // V1 - V5: OK
    address private immutable weth;
    //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

    // V1 - V5: OK
    mapping(address => address) internal \_bridges;

    // E1: OK
    event LogBridgeSet(address indexed token, address indexed bridge);
    // E1: OK
    event LogConvert(
        address indexed server,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amountSUSHI
    );

    constructor(
        address \_factory,
        address \_bar,
        address \_sushi,
        address \_weth
    ) public {
        factory = IUniswapV2Factory(\_factory);
        bar = \_bar;
        sushi = \_sushi;
        weth = \_weth;
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = \_bridges\[token\];
        if (bridge == address(0)) {
            bridge = weth;
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != sushi && token != weth && token != bridge,
            "SushiMaker: Invalid bridge"
        );

        // Effects
        \_bridges\[token\] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    // M1 - M5: OK
    // C1 - C24: OK
    // C6: It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "SushiMaker: must use EOA");
        \_;
    }

    // F1 - F10: OK
    // F3: \_convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    // F6: There is an exploit to add lots of SUSHI to the bar, run convert, then remove the SUSHI again.
    //     As the size of the SushiBar has grown, this requires large amounts of funds and isn't super profitable anymore
    //     The onlyEOA modifier prevents this being done with a flash loan.
    // C1 - C24: OK
    function convert(address token0, address token1) external onlyEOA() {
        \_convert(token0, token1);
    }

    // F1 - F10: OK, see convert
    // C1 - C24: OK
    // C3: Loop is under control of the caller
    function convertMultiple(
        address\[\] calldata token0,
        address\[\] calldata token1
) external onlyEOA() {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = token0.length;
        for (uint256 i = 0; i < len; i++) {
            \_convert(token0\[i\], token1\[i\]);
        }
    }

    // F1 - F10: OK
    // C1- C24: OK
    function \_convert(address token0, address token1) internal {
        // Interactions
        // S1 - S4: OK
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        require(address(pair) != address(0), "SushiMaker: Invalid pair");
        // balanceOf: S1 - S4: OK
        // transfer: X1 - X5: OK
        IERC20(address(pair)).safeTransfer(
            address(pair),
            pair.balanceOf(address(this))
        );
        // X1 - X5: OK
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }
        emit LogConvert(
            msg.sender,
            token0,
            token1,
            amount0,
            amount1,
            \_convertStep(token0, token1, amount0, amount1)
        );
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, \_swap, \_toSUSHI, \_convertStep: X1 - X5: OK
    function \_convertStep(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
) internal returns (uint256 sushiOut) {
        // Interactions
        if (token0 == token1) {
            uint256 amount = amount0.add(amount1);
            if (token0 == sushi) {
                IERC20(sushi).safeTransfer(bar, amount);
                sushiOut = amount;
            } else if (token0 == weth) {
                sushiOut = \_toSUSHI(weth, amount);
            } else {
                address bridge = bridgeFor(token0);
                amount = \_swap(token0, bridge, amount, address(this));
                sushiOut = \_convertStep(bridge, bridge, amount, 0);
            }
        } else if (token0 == sushi) {
            // eg. SUSHI - ETH
            IERC20(sushi).safeTransfer(bar, amount0);
            sushiOut = \_toSUSHI(token1, amount1).add(amount0);
        } else if (token1 == sushi) {
            // eg. USDT - SUSHI
            IERC20(sushi).safeTransfer(bar, amount1);
            sushiOut = \_toSUSHI(token0, amount0).add(amount1);
        } else if (token0 == weth) {
            // eg. ETH - USDC
            sushiOut = \_toSUSHI(
                weth,
                \_swap(token1, weth, amount1, address(this)).add(amount0)
            );
        } else if (token1 == weth) {
            // eg. USDT - ETH
            sushiOut = \_toSUSHI(
                weth,
                \_swap(token0, weth, amount0, address(this)).add(amount1)
            );
        } else {
            // eg. MIC - USDT
            address bridge0 = bridgeFor(token0);
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {
                // eg. MIC - USDT - and bridgeFor(MIC) = USDT
                sushiOut = \_convertStep(
                    bridge0,
                    token1,
                    \_swap(token0, bridge0, amount0, address(this)),
                    amount1
                );
            } else if (bridge1 == token0) {
                // eg. WBTC - DSD - and bridgeFor(DSD) = WBTC
                sushiOut = \_convertStep(
                    token0,
                    bridge1,
                    amount0,
                    \_swap(token1, bridge1, amount1, address(this))
                );
            } else {
                sushiOut = \_convertStep(
                    bridge0,
                    bridge1, // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                    \_swap(token0, bridge0, amount0, address(this)),
                    \_swap(token1, bridge1, amount1, address(this))
                );
            }
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function \_swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
) internal returns (uint256 amountOut) {
        // Checks
        // X1 - X5: OK
        IUniswapV2Pair pair =
            IUniswapV2Pair(factory.getPair(fromToken, toToken));
        require(address(pair) != address(0), "SushiMaker: Cannot convert");

        // Interactions
        // X1 - X5: OK
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        if (fromToken == pair.token0()) {
            amountOut =
                amountIn.mul(997).mul(reserve1) /
                reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            amountOut =
                amountIn.mul(997).mul(reserve0) /
                reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function \_toSUSHI(address token, uint256 amountIn)
        internal
        returns (uint256 amountOut)
{
        // X1 - X5: OK
        amountOut = \_swap(token, sushi, amountIn, bar);
    }
}

The constructor here directly initializes UniswapV2 Address of factory contract 、bar The address of the contract 、SUSHI The address of the contract 、WETH The address of the contract ：

    constructor(
        address \_factory,
        address \_bar,
        address \_sushi,
        address \_weth
    ) public {
        factory = IUniswapV2Factory(\_factory);
        bar = \_bar;
        sushi = \_sushi;
        weth = \_weth;
    }

bridgeFor Function to retrieve a token The bridge , If not set, the default is WETH：

    // F1 - F10: OK
    // C1 - C24: OK
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = \_bridges\[token\];
        if (bridge == address(0)) {
            bridge = weth;
        }
    }

setBridge Used to set a token The bridge ：

    // F1 - F10: OK
    // C1 - C24: OK
    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != sushi && token != weth && token != bridge,
            "SushiMaker: Invalid bridge"
        );

        // Effects
        \_bridges\[token\] = bridge;
        emit LogBridgeSet(token, bridge);
    }

Must be invoked using an external account ：

    // M1 - M5: OK
    // C1 - C24: OK
    // C6: It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "SushiMaker: must use EOA");
        \_;
    }

Conversion between two tokens ：

    // F1 - F10: OK
    // F3: \_convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    // F6: There is an exploit to add lots of SUSHI to the bar, run convert, then remove the SUSHI again.
    //     As the size of the SushiBar has grown, this requires large amounts of funds and isn't super profitable anymore
    //     The onlyEOA modifier prevents this being done with a flash loan.
    // C1 - C24: OK
    function convert(address token0, address token1) external onlyEOA() {
        \_convert(token0, token1);
    }

    // F1 - F10: OK
    // C1- C24: OK
    function \_convert(address token0, address token1) internal {
        // Interactions
        // S1 - S4: OK
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        require(address(pair) != address(0), "SushiMaker: Invalid pair");
        // balanceOf: S1 - S4: OK
        // transfer: X1 - X5: OK
        IERC20(address(pair)).safeTransfer(
            address(pair),
            pair.balanceOf(address(this))
        );
        // X1 - X5: OK
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }
        emit LogConvert(
            msg.sender,
            token0,
            token1,
            amount0,
            amount1,
            \_convertStep(token0, token1, amount0, amount1)
        );
    }
    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, \_swap, \_toSUSHI, \_convertStep: X1 - X5: OK
    function \_convertStep(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
) internal returns (uint256 sushiOut) {
        // Interactions
        if (token0 == token1) {
            uint256 amount = amount0.add(amount1);
            if (token0 == sushi) {
                IERC20(sushi).safeTransfer(bar, amount);
                sushiOut = amount;
            } else if (token0 == weth) {
                sushiOut = \_toSUSHI(weth, amount);
            } else {
                address bridge = bridgeFor(token0);
                amount = \_swap(token0, bridge, amount, address(this));
                sushiOut = \_convertStep(bridge, bridge, amount, 0);
            }
        } else if (token0 == sushi) {
            // eg. SUSHI - ETH
            IERC20(sushi).safeTransfer(bar, amount0);
            sushiOut = \_toSUSHI(token1, amount1).add(amount0);
        } else if (token1 == sushi) {
            // eg. USDT - SUSHI
            IERC20(sushi).safeTransfer(bar, amount1);
            sushiOut = \_toSUSHI(token0, amount0).add(amount1);
        } else if (token0 == weth) {
            // eg. ETH - USDC
            sushiOut = \_toSUSHI(
                weth,
                \_swap(token1, weth, amount1, address(this)).add(amount0)
            );
        } else if (token1 == weth) {
            // eg. USDT - ETH
            sushiOut = \_toSUSHI(
                weth,
                \_swap(token0, weth, amount0, address(this)).add(amount1)
            );
        } else {
            // eg. MIC - USDT
            address bridge0 = bridgeFor(token0);
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {
                // eg. MIC - USDT - and bridgeFor(MIC) = USDT
                sushiOut = \_convertStep(
                    bridge0,
                    token1,
                    \_swap(token0, bridge0, amount0, address(this)),
                    amount1
                );
            } else if (bridge1 == token0) {
                // eg. WBTC - DSD - and bridgeFor(DSD) = WBTC
                sushiOut = \_convertStep(
                    token0,
                    bridge1,
                    amount0,
                    \_swap(token1, bridge1, amount1, address(this))
                );
            } else {
                sushiOut = \_convertStep(
                    bridge0,
                    bridge1, // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                    \_swap(token0, bridge0, amount0, address(this)),
                    \_swap(token1, bridge1, amount1, address(this))
                );
            }
        }
    }
    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function \_swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
) internal returns (uint256 amountOut) {
        // Checks
        // X1 - X5: OK
        IUniswapV2Pair pair =
            IUniswapV2Pair(factory.getPair(fromToken, toToken));
        require(address(pair) != address(0), "SushiMaker: Cannot convert");

        // Interactions
        // X1 - X5: OK
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        if (fromToken == pair.token0()) {
            amountOut =
                amountIn.mul(997).mul(reserve1) /
                reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            amountOut =
                amountIn.mul(997).mul(reserve0) /
                reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }
    // F1 - F10: OK
    // C1 - C24: OK
    function \_toSUSHI(address token, uint256 amountIn)
        internal
        returns (uint256 amountOut)
{
        // X1 - X5: OK
        amountOut = \_swap(token, sushi, amountIn, bar);
    }

##### **SushiRoll**

SushiRoll Help you transfer existing Uniswap LP Token migration to SushiSwap LP token , The official source code is shown below ：

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Router01.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/libraries/UniswapV2Library.sol";

// SushiRoll helps your migrate your existing Uniswap LP tokens to SushiSwap LP ones
contract SushiRoll {
    using SafeERC20 for IERC20;

    IUniswapV2Router01 public oldRouter;
    IUniswapV2Router01 public router;

    constructor(IUniswapV2Router01 \_oldRouter, IUniswapV2Router01 \_router) public {
        oldRouter = \_oldRouter;
        router = \_router;
    }

    function migrateWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
) public {
        IUniswapV2Pair pair = IUniswapV2Pair(pairForOldRouter(tokenA, tokenB));
        pair.permit(msg.sender, address(this), liquidity, deadline, v, r, s);

        migrate(tokenA, tokenB, liquidity, amountAMin, amountBMin, deadline);
    }

    // msg.sender should have approved 'liquidity' amount of LP token of 'tokenA' and 'tokenB'
    function migrate(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
) public {
        require(deadline >= block.timestamp, 'SushiSwap: EXPIRED');

        // Remove liquidity from the old router with permit
        (uint256 amountA, uint256 amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            deadline
        );

        // Add liquidity to the new router
        (uint256 pooledAmountA, uint256 pooledAmountB) = addLiquidity(tokenA, tokenB, amountA, amountB);

        // Send remaining tokens to msg.sender
        if (amountA > pooledAmountA) {
            IERC20(tokenA).safeTransfer(msg.sender, amountA - pooledAmountA);
        }
        if (amountB > pooledAmountB) {
            IERC20(tokenB).safeTransfer(msg.sender, amountB - pooledAmountB);
        }
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
) internal returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairForOldRouter(tokenA, tokenB));
        pair.transferFrom(msg.sender, address(pair), liquidity);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'SushiRoll: INSUFFICIENT\_A\_AMOUNT');
        require(amountB >= amountBMin, 'SushiRoll: INSUFFICIENT\_B\_AMOUNT');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairForOldRouter(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = UniswapV2Library.sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                oldRouter.factory(),
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
) internal returns (uint amountA, uint amountB) {
        (amountA, amountB) = \_addLiquidity(tokenA, tokenB, amountADesired, amountBDesired);
        address pair = UniswapV2Library.pairFor(router.factory(), tokenA, tokenB);
        IERC20(tokenA).safeTransfer(pair, amountA);
        IERC20(tokenB).safeTransfer(pair, amountB);
        IUniswapV2Pair(pair).mint(msg.sender);
    }

    function \_addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
) internal returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        if (factory.getPair(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(address(factory), tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}

Constructor initializes the old UniswapV2Router Address and new UniswapV2Router Address ：

    constructor(IUniswapV2Router01 \_oldRouter, IUniswapV2Router01 \_router) public {
        oldRouter = \_oldRouter;
        router = \_router;
    }

migrateWithPermit Function to retrieve whether a transaction pair exists , Then call the transaction to the contract. permit Function to perform authorization operations , Last call migrate Migration ：

    function migrateWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        IUniswapV2Pair pair = IUniswapV2Pair(pairForOldRouter(tokenA, tokenB));
        pair.permit(msg.sender, address(this), liquidity, deadline, v, r, s);

        migrate(tokenA, tokenB, liquidity, amountAMin, amountBMin, deadline);
    }

    // msg.sender should have approved 'liquidity' amount of LP token of 'tokenA' and 'tokenB'
    function migrate(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) public {
        require(deadline >= block.timestamp, 'SushiSwap: EXPIRED');

        // Remove liquidity from the old router with permit
        (uint256 amountA, uint256 amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            deadline
        );

        // Add liquidity to the new router
        (uint256 pooledAmountA, uint256 pooledAmountB) = addLiquidity(tokenA, tokenB, amountA, amountB);

        // Send remaining tokens to msg.sender
        if (amountA > pooledAmountA) {
            IERC20(tokenA).safeTransfer(msg.sender, amountA - pooledAmountA);
        }
        if (amountB > pooledAmountB) {
            IERC20(tokenB).safeTransfer(msg.sender, amountB - pooledAmountB);
        }
    }

removeLiquidity Used to remove liquidity , After that, the liquidity token to be burned is transferred back to the transaction to the contract , Then the transaction pair is called. burn The function burns the liquidity tokens that fall in , Then extract the corresponding two tokens to the receiver , Then sort it out , Then perform the assignment operation , Then check whether the extracted corresponding token is greater than the minimum number of extracted tokens ：

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
) internal returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairForOldRouter(tokenA, tokenB));
        pair.transferFrom(msg.sender, address(pair), liquidity);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'SushiRoll: INSUFFICIENT\_A\_AMOUNT');
        require(amountB >= amountBMin, 'SushiRoll: INSUFFICIENT\_B\_AMOUNT');
    }

  // UniswapV2Pair.sol
    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 \_reserve0, uint112 \_reserve1,) = getReserves(); // gas savings
        address \_token0 = token0;                                // gas savings
        address \_token1 = token1;                                // gas savings
        uint balance0 = IERC20Uniswap(\_token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(\_token1).balanceOf(address(this));
        uint liquidity = balanceOf\[address(this)\];

        bool feeOn = \_mintFee(\_reserve0, \_reserve1);
        uint \_totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in \_mintFee
        amount0 = liquidity.mul(balance0) / \_totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / \_totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT\_LIQUIDITY\_BURNED');
        \_burn(address(this), liquidity);
        \_safeTransfer(\_token0, to, amount0);
        \_safeTransfer(\_token1, to, amount1);
        balance0 = IERC20Uniswap(\_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(\_token1).balanceOf(address(this));

        \_update(balance0, balance1, \_reserve0, \_reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

pairForOldRouter Used to calculate the of a pair without any external calls CREATE2 Address

    // calculates the CREATE2 address for a pair without making any external calls
    function pairForOldRouter(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = UniswapV2Library.sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                oldRouter.factory(),
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    

addLiquidity Used to increase liquidity ：

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal returns (uint amountA, uint amountB) {
        (amountA, amountB) = \_addLiquidity(tokenA, tokenB, amountADesired, amountBDesired);
        address pair = UniswapV2Library.pairFor(router.factory(), tokenA, tokenB);
        IERC20(tokenA).safeTransfer(pair, amountA);
        IERC20(tokenB).safeTransfer(pair, amountB);
        IUniswapV2Pair(pair).mint(msg.sender);
    }

    function \_addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        if (factory.getPair(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(address(factory), tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}

#### **safety problem**

Here we're going to look at the above SushiSwap Two security issues in the contract are briefly analyzed ：

##### **Conditional competition**

Vulnerability function ：emergencyWithdraw

Vulnerability code ：

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 \_pid) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[msg.sender\];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, \_pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

Vulnerability description ： As described in the code above , there emergencyWithdraw Function for emergency withdrawal , But the renewal of assets is after the transfer , Lead to conditional competition .

Solution ： The correct wording should be as follows

 function emergencyWithdraw(uint256 \_pid) public {
        PoolInfo storage pool = poolInfo\[\_pid\];
        UserInfo storage user = userInfo\[\_pid\]\[msg.sender\];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, \_pid, amount);
    }

##### **Reenter attack**

Vulnerability function ：setMigrator+migrate

Vulnerability code ：

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef \_migrator) public onlyOwner {
        migrator = \_migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 \_pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo\[\_pid\];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

Vulnerability description ： In the above code, you can see the contract owner You can set migrator, When migrator After the value of is determined migrator.migrate(lpToken) Can be determined accordingly , because migrate The way is through IMigratorChef Interface to be called , So when called ,migrate The logical code in the method will be based on migrator Values vary , At this point, if the smart contract owner take migrator The value of points to a containing malicious migrate Smart contract for method code , Then the owner can do any malicious operation he wants , It's even possible to empty all the tokens in the account , At the same time migrator.migrate(lpToken) After this line of code is executed , Contract owners can also exploit reentry attacks , Re execute from migrate Methods or other smart contract methods , Perform malicious operations .

Solution ： Setting up reasonable owner Authority

#### **Summary at the end of the paper**

SushiSwap Is in UniswapV2 Based on the agreement , Because its emergency reward model is more biased towards the interests of users , So compared with UniswapV2 It is easier to attract more users to participate in pledge to provide liquidity , At the same time, this article also reveals the problem of permission 、 Security risks exposed by coding logic design .

#### **Reference link**

https://app.sushi.com/

https://docs.sushi.com/

https://help.sushidocs.com/

https://sushiswapchef.medium.com
