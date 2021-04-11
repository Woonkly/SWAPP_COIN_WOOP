// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "../contracts/WonklyDEX.sol";

contract MockStakeManager is StakeManager {
    
    
    constructor()  StakeManager("ONLY TEST", "TEST")  public{
        
    }
    
    
    
    function MockaddOwner(address account) external returns(uint256){
        _lastIndexSowners=_lastIndexSowners.add(1);
        _SownersCount=  _SownersCount.add(1);
        
        _Sowners[_lastIndexSowners].account = account;
          _Sowners[_lastIndexSowners].flag = 1;
        
        _IDSownersIndex[account] = _lastIndexSowners;
        
        emit addNewInOwners(account);
        return _lastIndexSowners;
    }       
    
    
    
    
}


contract MockERC20tk is ERC20 {
  constructor() ERC20("ERC20 TOKEN TEST","TEST") public {
      _mint(msg.sender,100000*10**18);
  }
  
  function domint(address account, uint256 amount) public {
      _mint(account,amount);
  }
  
  function doallow(address owner,address spender, uint256 amount ) public {
      _approve( owner, spender, amount);
  }
  
}



contract MockWonclyDEX is WonklyDEX{
    
    
    constructor(
        address token_addr,
        uint32 fee,
        address operations,
        address beneficiary,
        address stake,
        address stakeSH,
        address woopSharedFunds
    )
    WonklyDEX(
        token_addr,
        fee,
        operations,
        beneficiary,
        stake,
        stakeSH,
         woopSharedFunds
        )
    
    public{
        
    }    
    
    
    function MockaddOwner(address account) external returns(uint256){
        _lastIndexSowners=_lastIndexSowners.add(1);
        _SownersCount=  _SownersCount.add(1);
        
        _Sowners[_lastIndexSowners].account = account;
          _Sowners[_lastIndexSowners].flag = 1;
        
        _IDSownersIndex[account] = _lastIndexSowners;
        
        emit addNewInOwners(account);
        return _lastIndexSowners;
    }       
    
    
    
    function MockTokenToCoin(uint256 token_amount)
        external
        returns (uint256)
    {
        require(!isPaused(), "1");

        require(
            token.allowance(msg.sender, address(this)) >= token_amount,
            "2"
        );

        require(totalLiquidity > 0, "3");

        require(!isOverLimit(token_amount, false), "4");

        uint256 token_reserve = token.balanceOf(address(this));

        uint256 eth_bought = price(token_amount, token_reserve, _coin_reserve);


        uint256 eth_bought0fee =
            planePrice(token_amount, token_reserve, _coin_reserve);


        require(eth_bought <= getMyCoinBalance(), "5");


    msg.sender.transfer(eth_bought);



        _coin_reserve = address(this).balance;


        return eth_bought;
/*


    require(token.transferFrom(msg.sender, address(this), token_amount));


        emit TokensSold(msg.sender, eth_bought, token_amount);

        uint256 eth_fee = eth_bought0fee - eth_bought;
        uint256 eth_bnPart;
        uint256 eth_opPart;
        uint256 eth_liqPart;

        (eth_bnPart, eth_liqPart, eth_opPart) = calcDeal(eth_fee);

     address(uint160(_operations)).transfer(eth_opPart);

        if (_woonckyPOS == address(0)) {
            address(uint160(_beneficiary)).transfer(eth_bnPart);
        } else {
            _triggerReward(eth_bnPart, true);
        }

        processRewardInfo memory slot;

        slot.dealed = _DealLiquidity(eth_liqPart, true, false);

        slot.dealed += _DealLiquidity(eth_liqPart, true, true);

        emit FeeCoins(
            eth_bnPart,
            eth_liqPart,
            eth_opPart,
            _beneficiary,
            _operations
        );

        if (slot.dealed > eth_liqPart) {
            return eth_bought;
        }

        uint256 leftover = eth_liqPart.sub(slot.dealed);

        if (leftover > 0) {
            address(uint160(_operations)).transfer(leftover);
            emit NewLeftover(_operations, leftover, true);
        }

        _coin_reserve = address(this).balance;

        return eth_bought;
*/        
    }
    
    
}