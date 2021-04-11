// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../contracts/Pausabled.sol";



contract testPausabledAndOwners is Pausabled {
    /// Define variables referring to different accounts
    Pausabled pausabled;
    address creator;
    address acc0;
    address acc1;
    
    

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // Here should instantiate tested contract
        creator=address(this);
        pausabled=new Pausabled();
        acc0 = TestsAccounts.getAccount(0); 
        acc1 = TestsAccounts.getAccount(1);
        pausabled.newInOwners(acc0 );
        pausabled.removeFromOwners(address(this));
    }


    /// Test if initial owner is set correctly
    function testInitialOwner() public {
        // account at zero index (account-0) is default account, so current owner should be acc0
        address owner=TestsAccounts.getAccount(0);
        Assert.equal(OwnerExist( TestsAccounts.getAccount(0) ), true, 'owner should be acc0');
    }
    
    
     /// Update owner first time
    /// This method will be called by default account(account-0) as there is no custom sender defined
    function addNewAccountToOwners() public {
        // check method caller is as expected
        Assert.ok(msg.sender == acc0, 'caller should be default account i.e. acc0');
        // update owner address to acc1
        newInOwners(acc1);
        // check if owner is set to expected account
        Assert.equal(OwnerExist( TestsAccounts.getAccount(1) ), true, 'owner should be updated to acc1');
    }

    //remove acc1 from owners
    function removeAccountFromOwners() public returns(bool){
        // check method caller is as expected
        Assert.ok(msg.sender == acc0, 'caller should be default account i.e. acc0');
        
        removeFromOwners(TestsAccounts.getAccount(1) );
        
        Assert.equal(!OwnerExist( TestsAccounts.getAccount(1) ), true, 'cannot remove acc1 from owners');
        
    }


    function checkIsPaused() public returns(bool){
        return Assert.equal(isPaused(),false,"Wrong paused inital state");
    }

  
  
    /// #sender: account-0
    function checkSetPaused() public returns(bool){

        Assert.equal(msg.sender, TestsAccounts.getAccount(0), "wrong sender in checkSetPaused is not account-0");        
        Assert.equal(_setPause(true),true,"Could not set pause to true")   ;
        Assert.equal(isPaused(),true,"Wrong paused state should be true");
        Assert.equal(_setPause(false),true,"Could not set pause to false")   ;
        return Assert.equal(isPaused(),false,"Wrong paused state should be false");
    }
    

    /// #sender: account-1
    function checkSetPausedFailureUsingNotOwner() public returns(bool){
        
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "wrong sender in checkSetPaused is not account-1");        

        
        try pausabled.setPause(true) returns (bool ok) {
            Assert.equal(ok, true, 'cannot set pause');
        } catch Error(string memory reason) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Own:!owners', 'failed with unexpected reason');
            
            
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            Assert.ok(false, 'failed unexpected');
            
        }
        
        return Assert.equal(pausabled.isPaused(),false,"Wrong paused state should be true");
    }


    /// #sender: account-0
    function checkRemoveAllStake() public {
        Assert.equal(stm.OwnerExist( msg.sender ), true, 'owner should be acc0');
        
        try stm.removeAllStake() {
            
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

        Assert.equal(stm.getStakeCount(),0,"FAIL to removeAllStake");
    
    }

}
