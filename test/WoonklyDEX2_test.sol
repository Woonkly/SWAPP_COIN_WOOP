// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "./MockWoncklyDEX.sol";

contract WonklyTEST is MockWonclyDEX {
    address creator;
    address acc0;
    address acc1;
    
    MockWonclyDEX wDEX;
    MockStakeManager liq;
    MockStakeManager liqSH;
    MockERC20tk cERC20;
    
    
constructor()
    MockWonclyDEX(
        0xd9145CCE52D386f254917e481eB44e9943F39138,
        9965,
        0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB,
        0x583031D1113aD414F02576BD6afaBfb302140225,
        0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8,
        0xf8e81D47203A594245E36C48e151709F0C19fBe8,
        0xdD870fA1b7C4700F2BD7f44238821C26f7392148
        )
    public{
    
    }    
    
    /// #gas: 600000000
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0); 
        acc1 = TestsAccounts.getAccount(1);
        
        liq=MockStakeManager(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8);
        liqSH=MockStakeManager(0xf8e81D47203A594245E36C48e151709F0C19fBe8);
        
        newInOwners(address(this));
        wDEX=MockWonclyDEX(address(this));
        cERC20=MockERC20tk(0xd9145CCE52D386f254917e481eB44e9943F39138);
        
        liq.MockaddOwner(address(this));
        
    }
    


    /// #sender: account-5
    /// #value: 1000000000000000000
    function checkCreatePool() public payable{
        
        
        Assert.equal(msg.value, 1000000000000000000 , 'FAIL invalid eth value');
        
        uint256 tkAmount=msg.value;
        cERC20.domint(address(this), tkAmount);
        cERC20.doallow(address(this), address(this) , tkAmount );

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


}