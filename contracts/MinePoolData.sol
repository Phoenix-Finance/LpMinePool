pragma solidity =0.5.16;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Halt.sol";
import "./Operator.sol";
import "./multiSignatureClient.sol";

contract MinePoolData is multiSignatureClient,Operator,Halt,ReentrancyGuard {
    
    address public phx ;
    address payable public lp;

   // address  public rewardDistribution;
    
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;

    uint256 public rewardPerduration; //reward token number per duration
    uint256 public duration;
    
    mapping(address => uint256) public rewards;   
        
    mapping(address => uint256) public userRewardPerTokenPaid;
    
    uint256 public periodFinish;
    uint256 public startTime;
    
    uint256 internal totalsupply;
    mapping(address => uint256) internal balances;

    uint256 public _phxFeeRatio ;//= 50;//5%
    uint256 public _htFeeAmount ;//= 1e16;
    address payable public _feeReciever;
    
}