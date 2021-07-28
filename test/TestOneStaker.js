const PoolProxy = artifacts.require('MinePoolProxy');
const MinePool = artifacts.require('MinePool');
const MockTokenFactory = artifacts.require('TokenFactory');
const Token = artifacts.require("TokenMock");
let multiSignature = artifacts.require("multiSignature");

const assert = require('chai').assert;
const Web3 = require('web3');
const config = require("../truffle.js");
const BN = require("bn.js");
var utils = require('./utils.js');
const { time, expectEvent} = require("@openzeppelin/test-helpers")

web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:7545"));

async function createApplication(multiSign,account,to,value,message){
  await multiSign.createApplication(to,value,message,{from:account});
  return await multiSign.getApplicationHash(account,to,value,message)
}

async function testViolation(message,testFunc){
  try {
    await testFunc();
    return true;
  } catch (error) {
    //console.log(error);
    return false;
  }
}

/**************************************************
 test case only for the ganahce command
 ganache-cli --port=7545 --gasLimit=8000000 --accounts=10 --defaultBalanceEther=100000 --blockTime 1
 **************************************************/
contract('MinePoolProxy', function (accounts){
    let minepool;
    let proxy;
    let tokenFactory;
    let lpToken1;
    let lpToken2;
    let fnxToken;
    let time1;

    let stakeAmount = web3.utils.toWei('100', 'ether');
    let userLpAmount = web3.utils.toWei('1000', 'ether');
    let staker1 = accounts[1];
    let staker2 = accounts[2];

    let fnxMineAmount = web3.utils.toWei('2000000', 'ether');
    let disSpeed = web3.utils.toWei('2', 'ether');
    let interval = 2;
    let reciever = accounts[4]


    let minutes = 60;
    let fiveMinutes = 5*60;
    let hour    = 60*60;
    let day     = 24*hour;
    let finishTime;
    let startTIme;
    before("init", async()=>{
        let addresses = [accounts[7],accounts[8],accounts[9]]
        mulSigInst = await multiSignature.new(addresses,2,{from : accounts[0]})

        minepool = await MinePool.new(mulSigInst.address);
        console.log("pool address:", minepool.address);

        proxy = await PoolProxy.new(minepool.address,mulSigInst.address);
        console.log("proxy address:",proxy.address);

        await proxy.setOperator(0,accounts[9]);

        tokenFactory = await MockTokenFactory.new();
        console.log("tokenfactory address:",tokenFactory.address);

        await tokenFactory.createToken(18);
        lpToken1 = await Token.at(await tokenFactory.createdToken());
        console.log("lptoken1 address:",lpToken1.address);

        await tokenFactory.createToken(18);
        fnxToken = await Token.at(await tokenFactory.createdToken());
        console.log("lptoken3 address:",fnxToken.address);

        //mock token set balance
        await lpToken1.adminSetBalance(staker1, userLpAmount);
        let staker1Balance =await lpToken1.balanceOf(staker1);
        //console.log(staker1Balance);
        assert.equal(staker1Balance,userLpAmount);

        await lpToken1.adminSetBalance(staker2, userLpAmount);

        await fnxToken.adminSetBalance(proxy.address,fnxMineAmount);

        //await web3.eth.transfer({from:accounts[0],value});
      //set mine coin info
        let res = await proxy.setPoolMineAddress(lpToken1.address,fnxToken.address);
        assert.equal(res.receipt.status,true);
        //set mine coin info
        res = await proxy.setMineRate(disSpeed,interval);
        assert.equal(res.receipt.status,true);

      //function setFeePara(uint256 fnxFeeRatio,uint256 htFeeAmount,address payable feeReciever)
       //res = await proxy.setFeePara(50,web3.utils.toWei("0.01",'ether'),reciever);
       //assert.equal(res.receipt.status,true);

      //set finshied time
        time1 = await tokenFactory.getBlockTime();
        console.log(time1);

        res = await proxy.setPeriodFinish(new BN(time1).add(new BN(fiveMinutes)),time1 + day);
        startTIme = time1;
        finishTime = time1 + day;
        assert.equal(res.receipt.status,true);

    })

   it("[0010] stake test and check mined balance,should pass", async()=>{
      let preMinerBalance = await proxy.totalRewards(staker1);
      console.log("before mine balance = " + preMinerBalance);

      let res = await lpToken1.approve(proxy.address,stakeAmount,{from:staker1});

     //res = await proxy.stake(stakeAmount,0,{from:staker1});
      time.increase(time.duration.seconds(fiveMinutes*2));
      console.log(await tokenFactory.getBlockTime())

      res = await proxy.deposit(0,stakeAmount,{from:staker1});
      assert.equal(res.receipt.status,true);

      //check totalStaked function
      let totalStaked = await proxy.totalStaked(0);
      assert.equal(totalStaked,stakeAmount);

      time.increase(time.duration.seconds(100))

     let info = await proxy.allPendingReward(0,staker1);
      console.log(info)

     let afterMinerBalance = info[1];
      console.log("after mine balance = " + afterMinerBalance);

      let diff = web3.utils.fromWei(afterMinerBalance.toString()) - web3.utils.fromWei(preMinerBalance.toString());

      let timeDiff = 100;

      console.log("mine balance = " + diff);
      assert.equal(diff>=timeDiff&&diff<=diff*(timeDiff+1),true);

		})

  it("[0020]get out mine reward,should pass", async()=>{
    console.log("\n\n");
    let preMinedAccountBalance = await fnxToken.balanceOf(staker1);
    let preRecieverBalance = await fnxToken.balanceOf(reciever);

    let preHtBalance = await web3.eth.getBalance(reciever);
    console.log(web3.utils.fromWei(new BN(preHtBalance.toString())));

    console.log("before mined token balance="+preMinedAccountBalance);

   // let res = await proxy.getReward({from:staker1});
    let res = await proxy.withdraw(0,0,{from:staker1});
    assert.equal(res.receipt.status,true);
    time.increase(time.duration.seconds(100))

    let afterMineAccountBalance = await fnxToken.balanceOf(staker1);

    console.log("after mined account balance = " + afterMineAccountBalance);

    let diff = web3.utils.fromWei(afterMineAccountBalance) - web3.utils.fromWei(preMinedAccountBalance);

    console.log("mine reward = " + diff);

  })


  it("[0030] stake out,should pass", async()=>{
    console.log("\n\n");
    let preLpBlance = await lpToken1.balanceOf(staker1);
    console.log("preLpBlance=" + preLpBlance);

    let v = await proxy.allPendingReward(0,staker1);
    preStakeBalance = v[0];
    console.log("before mine balance = " + preStakeBalance);

    let res = await proxy.withdraw(0,preStakeBalance,{from:staker1});
    assert.equal(res.receipt.status,true);

    v = await proxy.allPendingReward(0,staker1);
    let afterStakeBalance = v[0];

    console.log("after mine balance = " + afterStakeBalance);

    let diff = web3.utils.fromWei(preStakeBalance) - web3.utils.fromWei(afterStakeBalance);
    console.log("stake out balance = " + diff);

    let afterLpBlance = await lpToken1.balanceOf(staker1);
    console.log("afterLpBlance=" + afterLpBlance);
    let lpdiff = web3.utils.fromWei(afterLpBlance) - web3.utils.fromWei(preLpBlance);

    assert.equal(diff,lpdiff);
  })


  it("[0050] get back left mining token,should pass", async()=>{

    let msgData = proxy.contract.methods.getbackLeftMiningToken(staker1).encodeABI();
    let hash = await createApplication(mulSigInst,accounts[9],proxy.address,0,msgData);

    let res = await testViolation("multiSig setUserPhxUnlockInfo: This tx is not aprroved",async function(){
       await proxy.getbackLeftMiningToken(staker1,{from:accounts[9]});
    });
    assert.equal(res,false,"should return false")

    let index = await mulSigInst.getApplicationCount(hash)
    index = index.toNumber()-1;
    console.log(index);

    await mulSigInst.signApplication(hash,index,{from:accounts[7]})
    await mulSigInst.signApplication(hash,index,{from:accounts[8]})


      console.log("\n\n");
      let preMineBlance = await fnxToken.balanceOf(proxy.address);
      console.log("preMineBlance=" + preMineBlance);

      let preRecieverBalance = await fnxToken.balanceOf(staker1);
      console.log("before mine balance = " + preRecieverBalance);

      // res = await proxy.getbackLeftMiningToken(staker1,{from:accounts[9]});
      // assert.equal(res.receipt.status,true);
    res = await testViolation("multiSig setUserPhxUnlockInfo: This tx is aprroved",async function(){
      await proxy.getbackLeftMiningToken(staker1,{from:accounts[9]});
    });
    assert.equal(res,true,"should return false")

      let afterRecieverBalance = await  fnxToken.balanceOf(staker1);
      console.log("after mine balance = " + afterRecieverBalance);

      let diff = web3.utils.fromWei(afterRecieverBalance) - web3.utils.fromWei(preRecieverBalance);
      console.log("stake out balance = " + diff);

      let afterMineBlance = await fnxToken.balanceOf(proxy.address);
      console.log("afterMineBlance=" + afterMineBlance);

      let lpdiff = web3.utils.fromWei(preMineBlance) - web3.utils.fromWei(afterMineBlance);
      assert.equal(diff,lpdiff);

    })

    it("[0050] get mine info,should pass", async()=>{
       let res = await proxy.getMineInfo();
       console.log(res);

       assert.equal( web3.utils.fromWei(res[0]), web3.utils.fromWei(disSpeed));
       assert.equal(res[1].toNumber(),interval);
       assert.equal(res[2].toNumber(),new BN(startTIme).add(new BN(fiveMinutes)).toNumber());
       assert.equal(res[3].toNumber(),finishTime);
    })

})
