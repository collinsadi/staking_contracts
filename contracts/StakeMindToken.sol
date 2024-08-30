// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title This contract Allows a user to stake a certain amount of the (MND) token and get rewards;
/// @author Collins Adi
/// @notice a users can have multiple stakes, each stake is independent of the other and can be liquidated independently;
/// @dev for a developer the contract is quite straignt farward;

contract StakeMindToken {
    // This is a state variable to hold the MindToken Address
    // so we cam interact with it from the ERC20 Interface

    address public tokenAddress;

    // This is a Mapping of every user on the platform,
    // it's the the sum total of all the (MND), they have (actively) staked on the platform

    mapping(address => uint256) balances;

    // this struct is a structure of each stake
    // every stake takes in, amount staked, the time staked, the stake id,
    // and if the stake have been liquidated or not

    struct Stake {
        uint256 amount;
        uint256 timeStaked;
        address owner;
        uint256 id;
        bool liquidated;
    }

    // this is a mapping of a user's address to all the stakes they have on the platform
    // since users can have multiple stakes, their Unique Addresses, are mapped to their stakes

    mapping(address => Stake[]) stakes;

    // the constructor function triggers during deployment
    // so when deploying we are setting the token address,
    // which in this case is: 0x402d8DF98381c8dCd918B70532d78A8aDcC973Fa

    constructor() {
        tokenAddress = 0x402d8DF98381c8dCd918B70532d78A8aDcC973Fa;
    }

    // this is a sanity check modifier that ensures that zero address is not being used to interact with our contract
    // we could have done the check in every of the contract, but it cost lesser gas this way, and a cleaner code

    modifier sanityCheck() {
        require(msg.sender != address(0), "Address zero Detected");
        _;
    }

    // Events to emit when a token have been staked, and when it have been liquidated;

    event TokenStaked(address indexed staker, uint256 indexed amountStaked);
    event StakeWithdrawn(
        address indexed staker,
        uint256 indexed amountWithdrawn
    );

    // this function handles the logic for letting a user stake a specified amount of the (MND) token

    function stake(uint256 _amount) external sanityCheck {
        // we get the user's MND Balance

        uint256 _userMindTokenBalance = IERC20(tokenAddress).balanceOf(
            msg.sender
        );

        //  Check Allowance

        // here we check if the user actually has enough MND to stake

        require(_userMindTokenBalance >= _amount, "Insufficient Funds");

        // here we transfer the intended stake amount to the contract address
        // just so the contract can manage it and stake it for the user

        /*************************************
         *  BEFORE THIS FUNCTION WILL WORK   *
         * THE FRONTEND MUST HAVE INITIATED  *
         *    AN ERC20 'APPROVE' FUNCTION    *
         * THAT THE USER MUST HAVE ACCEPTED, *
         * ELSE WE WILL HAVE AN ERROR SAYING *
         *      'INSUFFICENT ALLOWANCE'      *
         *************************************/

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        // we get the users stakes from storage
        // we are going to add the new staking to it

        Stake[] storage userStakes = stakes[msg.sender];

        // we initialize the new staking
        // using the stake struct

        Stake memory newStake = Stake({
            amount: _amount,
            timeStaked: block.timestamp,
            owner: msg.sender,
            id: userStakes.length + 1,
            liquidated: false
        });

        //  her we push to the array containing the stakes of the user;

        userStakes.push(newStake);

        // her we increment the total number (MND) that the user has staked on the platform

        balances[msg.sender] += _amount;

        // emit an event when the token is staked

        emit TokenStaked(msg.sender, _amount);
    }

    // this function allows a user to liquidate(withdraw) their stakings
    // users will reeive all the (MND) tokens that they have staked
    // including a profit for how long the stake have been

    function liquidate(uint256 _stakeId) external sanityCheck {
        // we are expecting the _stakeId argument passed to be an integer
        // and it it going to be the index of the stake - 1
        // because when asigning the Id we did userStakes.length + 1
        // so we are substracting the exter 1, since array is 0 indexed

        uint256 index = _stakeId - 1;

        // we here we get the users stakes from the storage
        // so we can update the liquidity status later on

        Stake[] storage userStakes = stakes[msg.sender];

        // being sure if the index is not out of bound;

        require(index < userStakes.length, "Stake Id is Invalid");

        // get the stake indeded to liquidate

        Stake storage stakeToWithdraw = userStakes[index];

        // checking if the stake is already liquidated, return the function
        // this is just so the user does not get credited twice

        require(!stakeToWithdraw.liquidated, "Stake already Liquidated");

        /********************************************************************************************************
         * HERE WE ARE DOING THE NECESSARY DEDUCTION BEFORE WE ACTUALLY SEND THE TOKENS AND PROFIT TO THE USER  *
         * THAT'S BECAUSE WE ARE PROTECTING AGAINST REENTRANCY, SO EVEN IF THEY REENTER, THEY HAVE BEEN DEBITED *
         ********************************************************************************************************/

        balances[msg.sender] -= stakeToWithdraw.amount;

        // update the liquidated status

        stakeToWithdraw.liquidated = true;

        // send the token to the user

        IERC20(tokenAddress).transfer(msg.sender, stakeToWithdraw.amount);

        // emit an event indicating that a user liquidated

        emit StakeWithdrawn(msg.sender, stakeToWithdraw.amount);
    }

    /// @notice this function allows a user to get their total staked (MND) token
    /// @dev On the Frontend it can be displayed in an analytics tab
    /// @return returns the  total number of (MND) tokens staked
    function getTotalStakeBalance()
        external
        view
        sanityCheck
        returns (uint256)
    {
        return balances[msg.sender];
    }

    /// @notice this function allows a user to get al their stakes
    /// @dev On the Frontend it can be displayed in a table, so users can manage stakes with ease
    /// @return returns an array of all the stakes a user have made and an Empty Array if none;

    function getStakesForUser()
        external
        view
        sanityCheck
        returns (Stake[] memory)
    {
        return stakes[msg.sender];
    }

    /// @notice this function id to get details of particular stake
    /// @param _stakeId  this is the id of the stake to get,(expected to be the position of the stake + 1)
    /// @return returns an object containing details of a Stake

    function getDetailsOfASingleStake(
        uint256 _stakeId
    ) external view sanityCheck returns (Stake memory) {
        uint256 index = _stakeId - 1;

        Stake[] memory userStakes = stakes[msg.sender];
        require(index < userStakes.length, "Stake Id is Invalid");

        return userStakes[index];
    }

    function calculateReward() private {}
}
