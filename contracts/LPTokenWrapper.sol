pragma solidity =0.5.16;

import "./SafeMath.sol";
import "./MinePoolData.sol";
import "./IERC20.sol";

contract LPTokenWrapper is MinePoolData {
    
    using SafeMath for uint256;

    function totalSupply() public view returns(uint256) {
        return totalsupply;
    }

    function balanceOf(address account) public view returns(uint256) {
        return balances[account];
    }

    function stake(uint256 amount) internal {
        if(lp==address(0)) {
            require(msg.value>0,"stake input value is is 0");
            amount = msg.value;
            address payable poolAddr = address(uint160(address(this)));
            address(poolAddr).transfer(amount);
        } else {
            require(amount > 0, "cannot stake 0");
            uint256 preBalance = IERC20(lp).balanceOf(address(this));
            IERC20(lp).transferFrom(msg.sender,address(this), amount);
            uint256 afterBalance = IERC20(lp).balanceOf(address(this));
            require(afterBalance-preBalance==amount,"token stake transfer error!");
        }

        totalsupply = totalsupply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
    }

    function unstake (uint256 amount) internal {
        totalsupply = totalsupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        if(lp==address(0)) {
            msg.sender.transfer(amount);
        } else {
            uint256 preBalance = IERC20(lp).balanceOf(address(this));
            IERC20(lp).transfer(msg.sender, amount);
            uint256 afterBalance = IERC20(lp).balanceOf(address(this));
            require(preBalance - afterBalance==amount,"token unstake transfer error!");
        }
    }

    
}