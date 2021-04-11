// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "./MockWoncklyDEX.sol";


// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testWonklyDEX {
    MockWonclyDEX wDEX;
    MockStakeManager liq;
    MockStakeManager liqSH;
    MockERC20tk cERC20;
    address stm;
    address stmSH;
    address tokens;
    address payable wdex;
    address creator;
    address acc0;
    address acc1;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {

        tokens=0xd9145CCE52D386f254917e481eB44e9943F39138;
        stm=0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
        stmSH=0xf8e81D47203A594245E36C48e151709F0C19fBe8;
        wdex=0xE58469710853b35Dae8635EDA1484D4f404eaEa0;
        
        acc0 = TestsAccounts.getAccount(0); 
        acc1 = TestsAccounts.getAccount(1);

        
        liq=MockStakeManager(stm);
        liqSH=MockStakeManager(stmSH);
        wDEX=MockWonclyDEX(wdex);
        cERC20=MockERC20tk(tokens);
        
        

    }
    


    function setOwner() public {
         wDEX.MockaddOwner(address(this));
         Assert.equal(wDEX.OwnerExist( address(this) ), true, 'FAIL setOwner in DEX');
        liq.MockaddOwner(address(this));
        Assert.equal(liq.OwnerExist( address(this) ), true, 'FAIL setOwner in STM');
        liqSH.MockaddOwner(address(this));
        Assert.equal(liqSH.OwnerExist( address(this) ), true, 'FAIL setOwner in STMSH');
        
    }    
    
    
    function resetPool() public{

        if(!wDEX.isPaused() && wDEX.totalLiquidity() >0 ){
            
            liq.removeAllStake();
            
            liqSH.removeAllStake();
            
            try wDEX.closePool() returns (bool  ok) {
                Assert.ok(ok,  'cannot closePool in resetPool');
            } catch Error(string memory reason ) {
                // This is executed in case
                // revert was called inside getData
                // and a reason string was provided.
                // Compare failure reason, check if it is as expected
                Assert.equal(reason, 'wn:!owners', 'FAIL createPool sender not is owner');
                //Assert.notEqual(reason, 'Own:!owners', 'FAIL createPool sender not is owner');
                Assert.ok(false, 'FAIL resetPool expected reason');
                
            } catch (bytes memory /*lowLevelData*/) {
                // This is executed in case revert() was used
                // or there was a failing assertion, division
                // by zero, etc. inside getData.
                Assert.ok(false, 'FAIL resetPool unexpected');
                
            }
        }//if
        
        
    }//
    
    
    /// #sender: account-5
    /// #value: 1000000000000000000
    function checkCreatePool() public payable{
        
        
        Assert.equal(msg.value, 1000000000000000000 , 'FAIL invalid eth value');
        
        uint256 tkAmount=msg.value;
        cERC20.domint(address(this), tkAmount);
        cERC20.doallow(address(this), wdex , tkAmount );

        try wDEX.createPool{gas: 600000, value: msg.value}(tkAmount) returns (uint256 tl) {
            Assert.equal(tl,msg.value,  'cannot createPool');
        } catch Error(string memory reason ) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'wn:!owners', 'FAIL createPool sender not is owner');
            //Assert.notEqual(reason, 'Own:!owners', 'FAIL createPool sender not is owner');
            Assert.ok(false, 'failed expected reason');
            
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            Assert.ok(false, 'FAIL createPool unexpected');
            
        }
        
        
        Assert.equal(wDEX.totalLiquidity() ,msg.value,  'FAIL createPool liquidity mismatch');
        

        
    }
  
  

    function checkSwappTokenToCoin() public {
      
      
        uint256 initial= address(this).balance;
        uint256 tk=10**16;

        cERC20.domint(address(this), tk);
        
        Assert.greaterThan(cERC20.balanceOf(address(this))+1,initial,  'FAIL cannot checkSwappCoinToToken domint');
        
        cERC20.doallow(address(this), wdex , tk );
        
        Assert.greaterThan( wDEX.totalLiquidity(),uint256(0),  'FAIL cannot checkSwappCoinToToken totalLiquidity');

        Assert.ok(!wDEX.isOverLimit(tk, false),  'FAIL cannot checkSwappCoinToToken isOverLimit');
        

        try wDEX.MockTokenToCoin{gas: 60000000}(tk) returns (uint256 cb) {
            Assert.greaterThan(cb,uint256(0),  'cannot checkSwappTokenToCoin');
        } catch Error(string memory reason ) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'what', 'FAIL checkSwappTokenToCoin sender not is owner');
            //Assert.notEqual(reason, 'Own:!owners', 'FAIL createPool sender not is owner');
            Assert.ok(false, 'FAIL checkSwappTokenToCoin expected reason');
            
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            Assert.ok(false, 'FAIL checkSwappTokenToCoin unexpected');
            
        }
        
        
        uint256 current= address(this).balance;
        Assert.greaterThan(current,initial,  'FAIL cannot checkSwappTokenToCoin ');

  }


  
  
  
  /// #value: 100000
  function checkSwappCoinToToken() public payable{
      
      
        uint256 initial= cERC20.balanceOf(address(this));
        
        try wDEX.coinToToken{gas: 600000, value: msg.value}() returns (uint256 tb) {
            Assert.greaterThan(tb,uint256(0),  'cannot checkSwappCoinToToken');
        } catch Error(string memory reason ) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'what', 'FAIL checkSwappCoinToToken sender not is owner');
            //Assert.notEqual(reason, 'Own:!owners', 'FAIL createPool sender not is owner');
            Assert.ok(false, 'FAIL checkSwappCoinToToken expected reason');
            
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            Assert.ok(false, 'FAIL checkSwappCoinToToken unexpected');
            
        }
        
        uint256 current= cERC20.balanceOf(address(this));
        Assert.greaterThan(current,initial,  'FAIL cannot checkSwappCoinToToken ');

  }
  
  


  
      function closePool() public{
        resetPool();
    }    

  
      function resetOwner() public {
          
         if(wDEX.OwnerExist( address(this) )) {
            wDEX.removeFromOwners(address(this));    
         }
         
         Assert.equal(!wDEX.OwnerExist( address(this) ), true, 'FAIL resetOwner in DEX');

         if(liq.OwnerExist( address(this) )) {
            liq.removeFromOwners(address(this));    
         }
         
         Assert.equal(!liq.OwnerExist( address(this) ), true, 'FAIL resetOwner in STM');

         if(liqSH.OwnerExist( address(this) )) {
            liqSH.removeFromOwners(address(this));    
         }
         
         Assert.equal(!liqSH.OwnerExist( address(this) ), true, 'FAIL resetOwner in STMSH');
        
    }    



}
