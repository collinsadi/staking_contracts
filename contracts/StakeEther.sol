// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title This contract allows a user to stake Ether and receive rewards
/// @author Collins Adi
/// @notice A user can have multiple stakes, each stake is independent of the other and can be liquidated independently
/// @dev For a developer, the contract is quite straightforward

contract StakeEther {
    // This is a Mapping of every user on the platform,
    // it's the the sum total of all the Ether they have (actively) staked on the platform

    mapping(address => uint256) public balances;

    // This struct represents a single stake
    // Each stake includes the amount staked, the time staked, the stake ID,
    // whether the stake has been liquidated, and the reward for the stake

    struct Stake {
        uint256 amount;
        uint256 timeStaked;
        uint256 duration;
        address owner;
        uint256 id;
        bool liquidated;
        uint256 reward;
    }

    // This is a mapping of a user's address to all the stakes they have on the platform
    // Since users can have multiple stakes, their unique addresses are mapped to their stakes

    mapping(address => Stake[]) public stakes;

    // The constructor does not need to do anything specific for Ether staking
    constructor() {}

    // This modifier checks that the caller is not the zero address

    modifier sanityCheck() {
        require(msg.sender != address(0), "Address zero detected");
        _;
    }

    // Events to emit when Ether has been staked, and when it has been liquidated

    event EtherStaked(address indexed staker, uint256 indexed amountStaked);
    event StakeWithdrawn(
        address indexed staker,
        uint256 indexed amountWithdrawn
    );

    /// @notice This function allows a user to stake Ether for a specific duration
    /// @param _duration The duration for which the user wants to stake their Ether in days (30, 60, 90)

    function stake(uint256 _duration) external payable sanityCheck {
        require(
            _duration == 30 || _duration == 60 || _duration == 90,
            "Invalid staking duration"
        );
        require(msg.value > 0, "Amount must be greater than 0");

        // Calculate the reward based on time
        uint256 reward = calculateReward(msg.value, _duration);

        // Get the user's stakes from storage and initialize the new stake
        Stake[] storage userStakes = stakes[msg.sender];

        Stake memory newStake = Stake({
            amount: msg.value,
            timeStaked: block.timestamp,
            owner: msg.sender,
            id: userStakes.length + 1,
            liquidated: false,
            reward: reward,
            duration: _duration * 1 days
        });

        // Push the new stake to the user's stakes array
        userStakes.push(newStake);

        // Increment the total amount of Ether that the user has staked on the platform
        balances[msg.sender] += msg.value;

        // Emit an event when Ether is staked
        emit EtherStaked(msg.sender, msg.value);
    }

    // This function allows a user to liquidate (withdraw) their stakes
    // Users will receive all the Ether they have staked, including a profit for how long the stake has been

    function liquidate(uint256 _stakeId) external sanityCheck {
        uint256 index = _stakeId - 1;

        // Get the user's stakes from storage and ensure the index is valid
        Stake[] storage userStakes = stakes[msg.sender];
        require(index < userStakes.length, "Stake ID is invalid");

        // Get the stake intended to liquidate
        Stake storage stakeToWithdraw = userStakes[index];

        // Ensure the stake has not already been liquidated
        require(!stakeToWithdraw.liquidated, "Stake already liquidated");

        // Deduct the amount from the user's total staked balance
        balances[msg.sender] -= stakeToWithdraw.amount;

        stakeToWithdraw.liquidated = true;

        // Calculate the reward for the user
        uint256 reward = stakeToWithdraw.reward;

        // Check if this is an early withdrawal
        bool earlyWithdrawal = block.timestamp <
            (stakeToWithdraw.timeStaked + stakeToWithdraw.duration);

        if (earlyWithdrawal) {
            reward = 0;
        }

        // Add the reward to the total payout if there is any
        uint256 totalPayout = stakeToWithdraw.amount + reward;

        // Transfer the final payout to the user
        (bool success, ) = msg.sender.call{value: totalPayout}("");
        require(success, "Ether transfer failed");

        emit StakeWithdrawn(msg.sender, stakeToWithdraw.amount);
    }

    /// @notice This function allows a user to get their total staked Ether
    /// @dev On the frontend, it can be displayed in an analytics tab
    /// @return Returns the total number of Ether tokens staked
    function getTotalStakeBalance()
        external
        view
        sanityCheck
        returns (uint256)
    {
        return balances[msg.sender];
    }

    /// @notice This function allows a user to get all their stakes
    /// @dev On the frontend, it can be displayed in a table so users can manage stakes with ease
    /// @return Returns an array of all the stakes a user has made, and an empty array if none

    function getStakesForUser()
        external
        view
        sanityCheck
        returns (Stake[] memory)
    {
        return stakes[msg.sender];
    }

    /// @notice This function allows a user to get details of a particular stake
    /// @param _stakeId The ID of the stake to get (expected to be the position of the stake + 1)
    /// @return Returns an object containing details of a Stake
    function getDetailsOfASingleStake(
        uint256 _stakeId
    ) external view sanityCheck returns (Stake memory) {
        uint256 index = _stakeId - 1;

        Stake[] memory userStakes = stakes[msg.sender];
        require(index < userStakes.length, "Stake ID is invalid");

        return userStakes[index];
    }

    /// @notice This function calculates the reward based on the staked amount and duration
    /// @param _amount The amount of Ether staked
    /// @param _durationDays The duration in days for which the Ether is staked
    /// @return The calculated reward
    function calculateReward(
        uint256 _amount,
        uint256 _durationDays
    ) private pure returns (uint256) {
        uint256 reward = 0;

        if (_durationDays == 90) {
            reward = (_amount * 5) / 100; // 5% for 3 months
        } else if (_durationDays == 60) {
            reward = (_amount * 1) / 100; // 1% for 2 months
        } else if (_durationDays == 30) {
            reward = (_amount * 5) / 10000; // 0.05% for 1 month
        }

        return reward;
    }

    // Fallback function to accept Ether sent directly to the contract
    receive() external payable {}
}
