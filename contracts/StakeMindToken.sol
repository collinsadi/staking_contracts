// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeMindToken {
    address public tokenAddress;

    mapping(address => uint256) public balances;

    struct Stake {
        uint256 amount;
        uint256 timeStaked;
        address owner;
        uint256 id;
        bool liquidated;
    }

    mapping(address => Stake[]) public stakes;

    constructor() {
        tokenAddress = 0x402d8DF98381c8dCd918B70532d78A8aDcC973Fa;
    }

    modifier sanityCheck() {
        require(msg.sender != address(0), "Address zero Detected");
        _;
    }

    event TokenStaked(address indexed staker, uint256 indexed amountStaked);
    event StakeWithdrawn(
        address indexed staker,
        uint256 indexed amountWithdrawn
    );

    function stake(uint256 _amount) external sanityCheck {
        uint256 _userMindTokenBalance = IERC20(tokenAddress).balanceOf(
            msg.sender
        );
        require(_userMindTokenBalance >= _amount, "Insufficient Funds");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        Stake[] storage userStakes = stakes[msg.sender];

        Stake memory newStake = Stake({
            amount: _amount,
            timeStaked: block.timestamp,
            owner: msg.sender,
            id: userStakes.length + 1,
            liquidated: false
        });

        userStakes.push(newStake);
        balances[msg.sender] += _amount;

        emit TokenStaked(msg.sender, _amount);
    }

    function liquidate(uint256 _stakeId) external sanityCheck {
        uint256 index = _stakeId - 1;

        Stake[] storage userStakes = stakes[msg.sender];
        require(index < userStakes.length, "Stake Id is Invalid");

        Stake storage stakeToWithdraw = userStakes[index];
        require(!stakeToWithdraw.liquidated, "Stake already Liquidated");

        balances[msg.sender] -= stakeToWithdraw.amount;
        stakeToWithdraw.liquidated = true;

        IERC20(tokenAddress).transfer(msg.sender, stakeToWithdraw.amount);

        emit StakeWithdrawn(msg.sender, stakeToWithdraw.amount);
    }

    function getTotalStakeBalance()
        external
        view
        sanityCheck
        returns (uint256)
    {
        return balances[msg.sender];
    }

    function getStakesForUser()
        external
        view
        sanityCheck
        returns (Stake[] memory)
    {
        return stakes[msg.sender];
    }

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
