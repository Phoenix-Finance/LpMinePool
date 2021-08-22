pragma solidity =0.5.16;
import "./baseProxy.sol";
/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract MinePoolProxy is baseProxy {
    
    constructor (address implementation_,address _multiSignature)
        baseProxy(implementation_,_multiSignature)
        public
    {
    }
    /**
     * @dev default function for foundation input miner coins.
     */
    function()external payable{

    }
        
    function setPoolMineAddress(address /*_liquidpool*/,address /*_fnxaddress*/) public {
         delegateAndReturn();
    }    
    /**
     * @dev changer liquid pool distributed time interval , only foundation owner can modify database.
     * @  reward the distributed token amount in the time interval
     * @  mineInterval the distributed time interval.
     */
    function setMineRate(uint256 /*reward*/,uint256/*rewardinterval*/) public {
        delegateAndReturn();
    }

    /**
     * @dev getting back the left mine token
     * @ reciever the reciever for getting back mine token
     */
    function getbackLeftMiningToken(address /*reciever*/)  public {
        delegateAndReturn();
    }
  /**
   * @dev set period to finshi mining
   * @ _periodfinish the finish time
   */
    function setPeriodFinish(uint256 /*startTime*/,uint256 /*endTime*/)public {
        delegateAndReturn();
    }
     /**
     * @dev user stake in lp token
     * @  amount stake in amout
     */
    function stake(uint256 /*amount*/,bytes memory /*data*/) payable public {
         delegateAndReturn();
    }  
    
    
   /**
     * @dev user  unstake to cancel mine
      * @  amount stake in amout
     */
    function unstake(uint256 /*amount*/,bytes memory /*data*/) payable public {
         delegateAndReturn();
    }  
   
      /**
     * @dev user  unstake and get back reward
     * @  amount stake in amout
     */
    function exit() public {
         delegateAndReturn();
    }    

    /**
     * @dev user redeem mine rewards.
     */
    function getReward() payable public {
        delegateAndReturn();
    }    
    

///////////////////////////////////////////////////////////////////////////////////
    /**
     * @return Total number of distribution tokens balance.
     */
    function distributionBalance() public view returns (uint256) {
        delegateToViewAndReturn();
    }
  
    /**
     * The user to look up staking information for.
     * return The number of staking tokens deposited for addr.
     */
    function totalStakedFor(address /*addr*/) public view returns (uint256){
        delegateToViewAndReturn();
    }  
    
    
    /**
     * @dev retrieve user's stake balance.
     *  account user's account
     */
    function totalRewards(address /*account*/) public view returns (uint256) {
        delegateToViewAndReturn();
    }


  /**
     * @dev all stake token.
     * @return The number of staking tokens
     */
    function totalStaked(uint256 ) public view returns (uint256) {
         delegateToViewAndReturn();
    }

    /**
     * @dev get mine info
     */
    function getMineInfo() public view returns (uint256,uint256,uint256,uint256) {
        delegateToViewAndReturn();
    }
    
    function getVersion() public view returns (uint256) {
        delegateToViewAndReturn();
    }

    function setFeePara(uint256 /*fnxFeeRatio*/,uint256 /*htFeeAmount*/,address payable /*feeReciever*/) public {
        delegateAndReturn();
    }
//////////////////////////////////////////////////////////////////////////////////
    function deposit(uint256 /*_pid*/, uint256 /*_amount*/) public payable{
        delegateAndReturn();
    }

    function withdraw(uint256 /*_pid*/, uint256 /*_amount*/) public payable{
        delegateAndReturn();
    }

    function allPendingReward(uint256 /*_pid*/,address /*_user*/) public view returns(uint256,uint256,uint256){
        delegateToViewAndReturn();
    }

}