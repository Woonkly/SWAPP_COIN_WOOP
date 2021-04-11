// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../contracts/StakeManager.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testStakeManager {


    StakeManager stm;
    address creator;
    address acc0;
    address acc1;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    
    /// #sender: account-0
    function beforeAll() public {
        // Here should instantiate tested contract
        stm=new StakeManager("test stake manager", "TEST");
        acc0 = TestsAccounts.getAccount(0); 
        acc1 = TestsAccounts.getAccount(1);
        stm.newInOwners(acc0 );

        
    }
    
    /// #sender: account-0
    function setNewStake() public {
        Assert.equal(stm.OwnerExist( msg.sender ), true, 'owner should be acc0');
        
        try stm.newStake(TestsAccounts.getAccount(1), 10**18) returns (uint256 li) {
            Assert.equal(li, 1, 'cannot set newStake');
        } catch Error(string memory reason ) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            // Compare failure reason, check if it is as expected

            Assert.notEqual(reason, 'Own:!owners', 'FAIL sender not is owner');
            //Assert.ok(false, 'failed expected reason');
            
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            Assert.ok(false, 'failed unexpected');
            
        }

        Assert.equal(stm.getStakeCount(),1,"FAIL to create newStake");
    
    }



    /// #sender: account-0
    function checkAddToStake() public {
        Assert.equal(stm.OwnerExist( msg.sender ), true, 'owner should be acc0');
        
        try stm.addToStake(TestsAccounts.getAccount(1), 10**18) returns (uint256 li) {
            Assert.equal(li, 1, 'cannot set addToStake');
        } catch Error(string memory reason ) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            // Compare failure reason, check if it is as expected

            Assert.notEqual(reason, 'Own:!owners', 'FAIL sender not is owner');
            //Assert.ok(false, 'failed expected reason');
            
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            Assert.ok(false, 'failed unexpected');
            
        }


        //return (balanceOf(account), p.bnb, p.woop);
        uint256 balance=0;
        (balance,,)=stm.getStake(TestsAccounts.getAccount(1));

        Assert.equal(balance,2*10**18,"FAIL to addStake");
    
    }



    /// #sender: account-0
    function checkRenewStake() public {
        Assert.equal(stm.OwnerExist( msg.sender ), true, 'owner should be acc0');
        
        try stm.renewStake(TestsAccounts.getAccount(1), 10**18) returns (uint256 li) {
            Assert.equal(li, 1, 'cannot set renewStake');
        } catch Error(string memory reason ) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            // Compare failure reason, check if it is as expected

            Assert.notEqual(reason, 'Own:!owners', 'FAIL sender not is owner');
            //Assert.ok(false, 'failed expected reason');
            
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            Assert.ok(false, 'failed unexpected');
            
        }


        //return (balanceOf(account), p.bnb, p.woop);
        uint256 balance=0;
        (balance,,)=stm.getStake(TestsAccounts.getAccount(1));

        Assert.equal(balance,10**18,"FAIL to renewStake");
    
    }



    /// #sender: account-0
    function checkChangeRewardOp1() public {
        Assert.equal(stm.OwnerExist( msg.sender ), true, 'owner should be acc0 op1');
        
        try stm.changeReward(TestsAccounts.getAccount(1), 10**18,false,1) returns (bool ok) {
            Assert.ok(ok, 'cannot set changeReward token op1');
        } catch Error(string memory reason ) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            // Compare failure reason, check if it is as expected

            Assert.notEqual(reason, 'Own:!owners', 'FAIL sender not is owner');
            //Assert.ok(false, 'failed expected reason');
            
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            Assert.ok(false, 'failed unexpected token op1');
            
        }

        try stm.changeReward(TestsAccounts.getAccount(1), 10**18,true,1) returns (bool ok) {
            Assert.ok(ok, 'cannot set changeReward coin op1');
        } catch Error(string memory reason ) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            // Compare failure reason, check if it is as expected

            Assert.notEqual(reason, 'Own:!owners', 'FAIL sender not is owner');
            //Assert.ok(false, 'failed expected reason');
            
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            Assert.ok(false, 'failed unexpected coin op1');
            
        }



        //return (balanceOf(account), p.bnb, p.woop);
        uint256 rewCoin=0;
        uint256 rewtoken=0;
        (,rewCoin,rewtoken)=stm.getStake(TestsAccounts.getAccount(1));

        Assert.equal(rewCoin,10**18,"FAIL to changeReward coin op1");
        Assert.equal(rewtoken,10**18,"FAIL to changeReward token op1");
    
    }








}
