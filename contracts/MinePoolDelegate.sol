pragma solidity ^0.5.16;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./LPTokenWrapper.sol";
import "./Halt.sol";

contract MinePool is LPTokenWrapper {

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event HisReward(address indexed user, uint256 indexed reward,uint256 indexed idx);

    modifier updateReward(address account) {

        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            require(now >= startTime,"not reach start time");

            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;     
        }
        _;
    }

    constructor(address _multiSignature)
        multiSignatureClient(_multiSignature)
        public
    {
        
    }


    function update() onlyOwner public{
        //for the future use
    }

    function setPoolMineAddress(address payable _liquidpool,address _phxaddress) public onlyOwner{
       // require(_liquidpool != address(0));
        require(_phxaddress != address(0));
        
        lp  = _liquidpool;
        phx = _phxaddress;
    }
    
    function setMineRate(uint256 _reward,uint256 _duration) public onlyOwner updateReward(address(0)){
        //require(_reward>0);
        require(_duration>0);

        //token number per seconds
        rewardRate = _reward.div(_duration);
       // require(rewardRate > 0);

        rewardPerduration = _reward;
        duration = _duration;
    }   
    
    function setPeriodFinish(uint256 startime,uint256 endtime)public onlyOwner updateReward(address(0)) {
        //the setting time must pass timebeing
        require(startime >=now);
        require(endtime > startTime);
        
        //set new finish time
        lastUpdateTime = startime;
        periodFinish = endtime;
        startTime = startime;
    }  
    
    /**
     * @dev getting back the left mine token
     * @param reciever the reciever for getting back mine token
     */
    function getbackLeftMiningToken(address payable reciever)  public
        onlyOperator(0)
        validCall
    {
        uint256 bal =  IERC20(phx).balanceOf(address(this));
        IERC20(phx).transfer(reciever,bal);
        if(lp==address(0)){
            reciever.transfer(address(this).balance);
        }
    }

    function setFeePara(uint256 phxFeeRatio,uint256 htFeeAmount,address payable feeReciever) onlyOwner public {
        if(phxFeeRatio>0) {
            _phxFeeRatio = phxFeeRatio;
        }
        if(htFeeAmount >0 ) {
            _htFeeAmount = htFeeAmount;
        }
        if(feeReciever != address(0)){
            _feeReciever = feeReciever;
        }
    }

    function  collectFee(address mineCoin,uint256 amount) internal returns (uint256){
         if(_phxFeeRatio==0) {
             return amount;
         }
         require(msg.value>=_htFeeAmount,"need input ht coin value 0.01");
         //charged ht fee
        _feeReciever.transfer(_htFeeAmount);

        if (mineCoin != address(0)){
            //charge phx token fee
            uint256 fee = amount.mul(_phxFeeRatio).div(1000);
            IERC20 token = IERC20(mineCoin);
            uint256 preBalance = token.balanceOf(address(this));
            //ERC20(this).safeTransfer(token,_feeReciever,fee);
            token.transfer(_feeReciever, fee);
            uint256 afterBalance = token.balanceOf(address(this));
            require(preBalance - afterBalance == fee,"settlement token transfer error!");

            return amount.sub(fee);
        }

        return amount;
    }
//////////////////////////public function/////////////////////////////////    

    function lastTimeRewardApplicable() public view returns(uint256) {
         uint256 timestamp = Math.max(block.timestamp,startTime);
         return Math.min(timestamp,periodFinish);
     }

    function rewardPerToken() public view returns(uint256) {
        if (totalSupply() == 0 || now < startTime) {
            return rewardPerTokenStored;
        }
        
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
        );
    }

    function earned(address account) internal view returns(uint256) {
        return balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
     }

    //keep same name with old version
    function totalRewards(address account) public view returns(uint256) {
        return earned(account);
     }

    function stake(uint256 amount,bytes memory data) public updateReward(msg.sender) payable notHalted nonReentrant {

        require(now < periodFinish,"over finish time");//do not allow to stake after finish
        
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount,bytes memory data) public updateReward(msg.sender) payable notHalted nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        super.unstake(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() public notHalted nonReentrant {
        unstake(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) payable notHalted nonReentrant {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            //get fee for reciever
            //reward = collectFee(phx,reward);
            rewards[msg.sender] = 0;
            uint256 preBalance = IERC20(phx).balanceOf(address(this));
            IERC20(phx).transfer(msg.sender, reward);
            uint256 afterBalance = IERC20(phx).balanceOf(address(this));
            require(preBalance - afterBalance==reward,"phx award transfer error!");
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    /**
     * @return Total number of distribution tokens balance.
     */
    function distributionBalance() public view returns (uint256) {
        return IERC20(phx).balanceOf(address(this));
    }    

    /**
     * @param addr The user to look up staking information for.
     * @return The number of staking tokens deposited for addr.
     */
    function totalStakedFor(address addr) public view returns (uint256) {
        return super.balanceOf(addr);
    }
    
    /**
     * @dev all stake token.
     * @return The number of staking tokens
     */

    function getMineInfo() public view returns (uint256,uint256,uint256,uint256) {
        return (rewardPerduration,duration,startTime,periodFinish);
    }
    
    function getVersion() public view returns (uint256) {
        return 1;
    }
///////////////////////////////////////////////////////////////////////////////////////
    function deposit(uint256 _pid, uint256 _amount)  public payable {
        bytes memory data = new bytes(1);
        stake(_amount,data);
    }

    function withdraw(uint256 _pid, uint256 _amount) public payable{
        if(_amount==0) {
            getReward();
        }else {
            bytes memory data = new bytes(1);
            unstake(_amount,data);
        }
    }

    function allPendingReward(uint256 _pid,address _user) public view returns(uint256,uint256,uint256){
        return (totalStakedFor(_user),totalRewards(_user),0);
    }

    function totalStaked(uint256 _pid) public view returns (uint256){
        return super.totalSupply();
    }


}
