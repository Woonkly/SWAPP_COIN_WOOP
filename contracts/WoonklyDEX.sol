// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/token/ERC20/ERC20.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/utils/ReentrancyGuard.sol";
import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/StakeManager.sol";
import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/IwoonklyPOS.sol";
import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/IWStaked.sol";
import "https://github.com/Woonkly/MartinHSolUtils/PausabledLMH.sol";

/**
MIT License

Copyright (c) 2021 Woonkly OU

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED BY WOONKLY OU "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

contract WonklyDEX is Owners, PausabledLMH, ReentrancyGuard {
    using SafeMath for uint256;

    //Section Type declarations
    struct Stake {
        address account;
        uint256 bnb;
        uint256 bal;
        uint256 woop;
        uint8 flag;
    }

    struct processRewardInfo {
        uint256 remainder;
        uint256 woopsRewards;
        uint256 dealed;
        address me;
        bool resp;
    }

    //Section State variables
    IERC20 token;
    uint256 public totalLiquidity;
    uint32 internal _fee;
    uint32 internal _baseFee;
    address internal _operations;
    address internal _beneficiary;
    uint256 internal _coin_reserve;
    address internal _noderew;
    address internal _woonclyBEP20;
    IWStaked internal _stakes;
    address internal _stakeable;
    IWStaked internal _stakesSH;
    address internal _stakeableSH;
    address internal _woopSharedFunds;

    uint256 internal _rewPend = 0;
    uint256 internal _rewPendCOIN = 0;

    //Section Modifier

    //Section Events
    event FeeChanged(uint32 oldFee, uint32 newFee);
    event BaseFeeChanged(uint32 oldbFee, uint32 newbFee);
    event AddressChanged(address olda, address newa, uint8 id);
    event CoinReceived(uint256 coins);
    event PoolCreated(
        uint256 totalLiquidity,
        address investor,
        uint256 token_amount
    );
    event PoolClosed(
        uint256 eth_reserve,
        uint256 token_reserve,
        uint256 liquidity,
        address destination
    );
    event InsuficientRewardFund(address account, bool isCoin, bool isSH);
    event NewLeftover(address account, uint256 leftover, bool isCoin);
    event PurchasedTokens(
        address purchaser,
        uint256 coins,
        uint256 tokens_bought
    );
    event FeeTokens(
        uint256 bnPart,
        uint256 liqPart,
        uint256 opPart,
        uint256 nodPart,
        address beneficiary,
        address operations,
        address nodes
    );
    event TokensSold(address vendor, uint256 eth_bought, uint256 token_amount);
    event FeeCoins(
        uint256 bnPart,
        uint256 liqPart,
        uint256 opPart,
        uint256 nodPart,
        address beneficiary,
        address operations,
        address nodes
    );
    event LiquidityChanged(uint256 oldLiq, uint256 newLiq, bool isSH);

    event LiquidityWithdraw(
        address investor,
        uint256 coins,
        uint256 token_amount,
        uint256 newliquidity,
        bool isSH
    );

    //Section functions

    constructor(
        address token_addr,
        uint32 fee,
        address operations,
        address beneficiary,
        address stake,
        address stakeSH,
        address woopSharedFunds,
        address noderew
    ) public {
        token = IERC20(token_addr);
        _woonclyBEP20 = token_addr;
        _fee = fee;
        _paused = true;
        _beneficiary = beneficiary;
        _operations = operations;
        _baseFee = 10000;
        _coin_reserve = 0;
        _noderew = address(0);
        _stakeable = stake;
        _stakes = IWStaked(stake);
        _stakeableSH = stakeSH;
        _stakesSH = IWStaked(stakeSH);
        _woopSharedFunds = woopSharedFunds;
        _noderew = noderew;
    }

    function getValues()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (_coin_reserve, _fee, _baseFee, _rewPend, _rewPendCOIN);
    }

    function setFee(uint32 newFee) external onlyIsInOwners returns (bool) {
        require((newFee > 0 && newFee <= 1000000), "1");
        uint32 old = _fee;
        _fee = newFee;
        emit FeeChanged(old, _fee);
        return true;
    }

    function setBaseFee(uint32 newbFee) external onlyIsInOwners returns (bool) {
        require((newbFee > 0 && newbFee <= 1000000), "1");
        uint32 old = _baseFee;
        _baseFee = newbFee;
        emit FeeChanged(old, _baseFee);
        return true;
    }

    function setPendRew(uint256 amount, bool isCOIN)
        external
        onlyIsInOwners
        returns (uint256)
    {
        if (isCOIN == true) {
            _rewPendCOIN = amount;
        } else {
            _rewPend = amount;
        }
        return amount;
    }

    function getAddress()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            address
        )
    {
        return (
            _operations,
            _noderew,
            _beneficiary,
            _stakeable,
            _stakeableSH,
            _woopSharedFunds
        );
    }

    function setAddress(address newa, uint8 id)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(newa != address(0), "1");

        address old;

        if (id == 1) {
            old = _operations;
            _operations = newa;
        }

        if (id == 2) {
            old = _noderew;
            _noderew = newa;
        }

        if (id == 3) {
            old = _beneficiary;
            _beneficiary = newa;
        }

        if (id == 4) {
            old = _stakeable;
            _stakeable = newa;
            _stakes = IWStaked(newa);
        }

        if (id == 5) {
            old = _stakeableSH;
            _stakeableSH = newa;
            _stakesSH = IWStaked(newa);
        }

        if (id == 7) {
            old = _woopSharedFunds;
            _woopSharedFunds = newa;
        }

        emit AddressChanged(old, newa, id);
        return true;
    }

    receive() external payable {
        /*
        if (!isPaused()) {
            coinToToken();
        }
        
        emit CoinReceived(msg.value);
        */
        _coin_reserve = getMyCoinBalance();
    }

    /*
    function addCoin() external payable returns (bool) {
        //_coin_reserve = address(this).balance;
        
        _coin_reserve = getMyCoinBalance();
        return true;
    }

*/

    fallback() external payable {
        //  emit CoinReceived(msg.value);
    }

    function getMyCoinBalance() public view returns (uint256) {
        //    return address(this).balance;
        address my = address(this);
        return my.balance;
    }

    function getMyTokensBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getSCtokenAddress() public view returns (address) {
        return address(token);
    }

    function _addStake(
        address account,
        uint256 amount,
        bool isSH
    ) internal returns (bool) {
        IWStaked stk = getSTK(isSH);

        if (!stk.StakeExist(account)) {
            stk.newStake(account, amount);
        } else {
            stk.addToStake(account, amount);
        }

        return true;
    }

    function createPool(uint256 token_amount)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(
            token.allowance(_msgSender(), address(this)) >= token_amount,
            "0"
        );

        require(!_stakes.StakeExist(_msgSender()), "1");
        require(totalLiquidity == 0, "2");
        require(msg.value > 0, "3");
        //totalLiquidity = address(this).balance;
        totalLiquidity = getMyCoinBalance();
        _coin_reserve = totalLiquidity;

        _addStake(_msgSender(), totalLiquidity, false);

        require(token.transferFrom(_msgSender(), address(this), token_amount));
        _paused = false;
        emit PoolCreated(totalLiquidity, _msgSender(), token_amount);
        return totalLiquidity;
    }

    function migratePool(uint256 token_amount, uint256 newLiq)
        external
        payable
        onlyIsInOwners
        nonReentrant
        returns (uint256)
    {
        require(isPaused(), "1");

        require(
            token.allowance(_msgSender(), address(this)) >= token_amount,
            "2"
        );

        require(totalLiquidity == 0, "3");

        require(msg.value > 0, "4");

        totalLiquidity = newLiq;
        _coin_reserve = getMyCoinBalance(); // address(this).balance;

        require(token.transferFrom(_msgSender(), address(this), token_amount));
        _paused = false;
        emit PoolCreated(_coin_reserve, _msgSender(), token_amount);
        return totalLiquidity;
    }

    function closePool() public onlyIsInOwners nonReentrant returns (bool) {
        require(totalLiquidity > 0, "5");

        uint256 token_reserve = token.balanceOf(address(this));

        require(token.transfer(_operations, token_reserve), "6");
        address payable ow = address(uint160(_operations));

        _coin_reserve = getMyCoinBalance(); //address(this).balance;
        ow.transfer(_coin_reserve);

        uint256 liq = totalLiquidity;
        totalLiquidity = 0;
        _coin_reserve = 0;
        setPause(true);
        emit PoolClosed(_coin_reserve, token_reserve, liq, ow);
        return true;
    }

    function price(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256) {
        uint256 input_amount_with_fee = input_amount.mul(uint256(_fee));
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator =
            input_reserve.mul(_baseFee).add(input_amount_with_fee);
        return numerator / denominator;
    }

    function planePrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256) {
        uint256 input_amount_with_fee0 = input_amount.mul(uint256(_baseFee));
        uint256 numerator = input_amount_with_fee0.mul(output_reserve);
        uint256 denominator =
            input_reserve.mul(_baseFee).add(input_amount_with_fee0);
        return numerator / denominator;
    }

    function calcDeal(uint256 amount)
        public
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 stake = amount.mul(250) / 1000;
        uint256 liq = amount.mul(500) / 1000;
        uint256 nodos = amount.mul(125) / 1000;
        uint256 oper = amount - (stake + liq + nodos);

        return (stake, liq, oper, nodos);
    }

    function isOverLimit(uint256 amount, bool isCoin)
        public
        view
        returns (bool)
    {
        if (getPercImpact(amount, isCoin) > 10) {
            return true;
        }
        return false;
    }

    function getPercImpact(uint256 amount, bool isCoin)
        public
        view
        returns (uint8)
    {
        uint256 reserve = 0;

        if (isCoin) {
            reserve = _coin_reserve;
        } else {
            reserve = token.balanceOf(address(this));
        }

        uint256 p = amount.mul(100) / reserve;

        if (p <= 100) {
            return uint8(p);
        } else {
            return uint8(100);
        }
    }

    function getMaxAmountSwap() public view returns (uint256, uint256) {
        return (
            _coin_reserve.mul(10) / 100,
            token.balanceOf(address(this)).mul(10) / 100
        );
    }

    function currentTokensToCoin(uint256 token_amount)
        public
        view
        returns (uint256)
    {
        uint256 token_reserve = token.balanceOf(address(this));
        return price(token_amount, token_reserve, _coin_reserve);
    }

    function currentCoinToTokens(uint256 coin_amount)
        public
        view
        returns (uint256)
    {
        uint256 token_reserve = token.balanceOf(address(this));
        return price(coin_amount, _coin_reserve, token_reserve);
    }

    function WithdrawReward(
        uint256 amount,
        bool isCoin,
        bool isSH
    ) external nonReentrant returns (bool) {
        IWStaked stk = getSTK(isSH);

        require(!isPaused(), "1");

        require(stk.StakeExist(_msgSender()), "2");

        _withdrawReward(_msgSender(), amount, isCoin, isSH);

        return true;
    }

    function getSTK(bool isSH) internal view returns (IWStaked) {
        if (isSH) {
            return _stakesSH;
        }

        return _stakes;
    }

    function _withdrawReward(
        address account,
        uint256 amount,
        bool isCoin,
        bool isSH
    ) internal returns (bool) {
        require(!isPaused(), "1");

        IWStaked stk = getSTK(isSH);

        require(stk.StakeExist(account), "2");

        uint256 bnb = 0;
        uint256 woop = 0;

        (bnb, woop) = stk.getReward(account);

        uint256 remainder = 0;

        if (isCoin) {
            require(amount <= bnb, "3");

            require(amount <= getMyCoinBalance(), "4");

            address(uint160(account)).transfer(amount);

            remainder = bnb.sub(amount);
        } else {
            //token

            require(amount <= woop, "5");

            require(amount <= getMyTokensBalance(), "6");

            require(token.transfer(account, amount), "7");

            remainder = woop.sub(amount);
        }

        _coin_reserve = getMyCoinBalance(); //address(this).balance;

        stk.changeReward(account, remainder, isCoin, 1);
    }

    function getCalcRewardAmount(
        address account,
        uint256 amount,
        bool isSH
    ) public view returns (uint256, uint256) {
        IWStaked stk = getSTK(isSH);

        if (!stk.StakeExist(account) || totalLiquidity == 0) return (0, 0);

        (uint256 liq, , ) = stk.getStake(account);

        uint256 part = (liq * amount) / totalLiquidity;

        return (part, amount - part);
    }

    function substractRewPend(uint256 amount, bool isCOIN)
        internal
        returns (bool)
    {
        if (isCOIN != true) {
            if (_rewPend >= amount) {
                _rewPend = _rewPend.sub(amount);
            } else {
                _rewPend = 0;
            }
        } else {
            if (_rewPendCOIN >= amount) {
                _rewPendCOIN = _rewPendCOIN.sub(amount);
            } else {
                _rewPendCOIN = 0;
            }
        }
    }

    function _dealLiquidity(
        uint256 amount,
        uint256 distributed,
        uint256 indFrom,
        uint256 indTo,
        bool isCoin,
        bool isSH
    ) internal returns (uint256) {
        processRewardInfo memory slot;
        slot.dealed = 0;
        Stake memory p;

        IWStaked stk = getSTK(isSH);

        uint256 last = stk.getLastIndexStakes();

        if (last == 0 || indFrom > last) {
            return 0;
        }

        if (indTo > last) {
            indTo = last;
        }

        for (uint256 i = indFrom; i < (indTo + 1); i++) {
            (p.account, p.bal, p.bnb, p.woop, p.flag) = stk.getStakeByIndex(i);
            if (p.flag == 1) {
                (slot.woopsRewards, slot.remainder) = getCalcRewardAmount(
                    p.account,
                    amount,
                    isSH
                );
                if (slot.woopsRewards > 0) {
                    stk.changeReward(p.account, slot.woopsRewards, isCoin, 2);
                    slot.dealed = slot.dealed.add(slot.woopsRewards);

                    if (amount < (distributed + slot.dealed)) {
                        substractRewPend(slot.dealed, isCoin);

                        emit InsuficientRewardFund(p.account, isCoin, isSH);
                        return 0;
                    }
                } else {
                    //emit InsuficientRewardFund(p.account, isCoin, isSH);
                }
            }
        } //for

        substractRewPend(slot.dealed, isCoin);
        return slot.dealed;
    }

    function processLeftOVER(uint256 leftover)
        public
        nonReentrant
        onlyIsInOwners
        returns (bool)
    {
        require(!isPaused(), "1");

        require(leftover > 0, "2");

        require(token.transfer(_operations, leftover), "8");
        emit NewLeftover(_operations, leftover, false);

        return true;
    }

    function processReward(
        uint256 tokens_liqPart,
        uint256 distributed,
        uint256 indFrom,
        uint256 indTo
    ) public nonReentrant onlyIsInOwners returns (uint256) {
        require(!isPaused(), "1");

        require(indFrom <= indTo, "2");

        //(stake, liq, oper)
        //(, uint256 tokens_liqPart,,) = calcDeal(tokens_fee);

        processRewardInfo memory slot;

        slot.dealed = _dealLiquidity(
            tokens_liqPart,
            distributed,
            indFrom,
            indTo,
            false,
            false
        );

        slot.dealed += _dealLiquidity(
            tokens_liqPart,
            distributed + slot.dealed,
            indFrom,
            indTo,
            false,
            true
        );

        return slot.dealed;
    }

    function coinToToken() public payable nonReentrant returns (uint256) {
        require(!isPaused(), "1");

        require(totalLiquidity > 0, "2");

        require(!isOverLimit(msg.value, true), "3");

        uint256 token_reserve = token.balanceOf(address(this));

        uint256 tokens_bought = price(msg.value, _coin_reserve, token_reserve);

        uint256 tokens_bought0fee =
            planePrice(msg.value, _coin_reserve, token_reserve);

        _coin_reserve = getMyCoinBalance(); // address(this).balance;

        require(tokens_bought <= getMyTokensBalance(), "4");
        require(token.transfer(_msgSender(), tokens_bought), "5");

        emit PurchasedTokens(_msgSender(), msg.value, tokens_bought);

        uint256 tokens_fee = tokens_bought0fee - tokens_bought;

        // require(token.transfer(_beneficiary2, tokens_fee), "6");

        (
            uint256 tokens_bnPart,
            uint256 tokens_liqPart,
            uint256 tokens_opPart,
            uint256 tokens_nodPart
        ) = calcDeal(tokens_fee);

        require(token.transfer(_beneficiary, tokens_bnPart), "6");

        require(token.transfer(_operations, tokens_opPart), "7");

        require(token.transfer(_noderew, tokens_nodPart), "8");

        _rewPend = _rewPend.add(tokens_liqPart);

        _coin_reserve = getMyCoinBalance(); //address(this).balance;

        return tokens_bought;
    }

    function processLeftOVERCOIN()
        public
        payable
        nonReentrant
        onlyIsInOwners
        returns (bool)
    {
        require(!isPaused(), "1");

        require(msg.value > 0, "2");

        address(uint160(_operations)).transfer(msg.value);

        _coin_reserve = getMyCoinBalance(); // address(this).balance;

        emit NewLeftover(_operations, msg.value, true);

        return true;
    }

    function processRewardCOIN(
        uint256 eth_liqPart,
        uint256 distributed,
        uint256 indFrom,
        uint256 indTo
    ) public nonReentrant onlyIsInOwners returns (uint256) {
        require(!isPaused(), "1");

        require(indFrom <= indTo, "2");

        //(stake, liq, oper,node)
        //(,uint256 eth_liqPart,,) = calcDeal(amount);

        processRewardInfo memory slot;

        slot.dealed = _dealLiquidity(
            eth_liqPart,
            distributed,
            indFrom,
            indTo,
            true,
            false
        );

        slot.dealed += _dealLiquidity(
            eth_liqPart,
            distributed + slot.dealed,
            indFrom,
            indTo,
            true,
            true
        );

        return slot.dealed;
    }

    function tokenToCoin(uint256 token_amount)
        external
        nonReentrant
        returns (uint256)
    {
        require(!isPaused(), "1");

        require(
            token.allowance(_msgSender(), address(this)) >= token_amount,
            "2"
        );

        require(totalLiquidity > 0, "3");

        require(!isOverLimit(token_amount, false), "4");

        uint256 token_reserve = token.balanceOf(address(this));

        uint256 eth_bought = price(token_amount, token_reserve, _coin_reserve);

        uint256 eth_bought0fee =
            planePrice(token_amount, token_reserve, _coin_reserve);

        require(eth_bought <= getMyCoinBalance(), "5");

        _msgSender().transfer(eth_bought);

        _coin_reserve = getMyCoinBalance(); // address(this).balance;

        require(token.transferFrom(_msgSender(), address(this), token_amount));

        emit TokensSold(_msgSender(), eth_bought, token_amount);

        uint256 eth_fee = eth_bought0fee - eth_bought;

        //address(uint160(_beneficiary2)).transfer(eth_fee);

        //(stake, liq, oper, node)
        (
            uint256 eth_bnPart,
            uint256 eth_liqPart,
            uint256 eth_opPart,
            uint256 eth_nodPart
        ) = calcDeal(eth_fee);

        address(uint160(_operations)).transfer(eth_opPart);

        address(uint160(_beneficiary)).transfer(eth_bnPart);

        address(uint160(_noderew)).transfer(eth_nodPart);

        _coin_reserve = getMyCoinBalance(); // address(this).balance;

        _rewPendCOIN = _rewPendCOIN.add(eth_liqPart);

        return eth_bought;
    }

    function calcTokenToAddLiq(uint256 coinDeposit)
        public
        view
        returns (uint256)
    {
        return
            (coinDeposit.mul(token.balanceOf(address(this))).div(_coin_reserve))
                .add(1);
    }

    function AddLiquidity(bool isSH)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(!isPaused(), "1");

        uint256 eth_reserve = _coin_reserve;

        uint256 token_amount = calcTokenToAddLiq(msg.value);

        address origin = _msgSender();

        if (isSH) {
            origin = _woopSharedFunds;
        }

        require(
            origin != address(0) &&
                token.allowance(origin, address(this)) >= token_amount,
            "2"
        );

        uint256 liquidity_minted =
            msg.value.mul(totalLiquidity).div(eth_reserve);

        _coin_reserve = getMyCoinBalance(); // address(this).balance;

        _addStake(_msgSender(), liquidity_minted, isSH);

        uint256 oldLiq = totalLiquidity;

        totalLiquidity = totalLiquidity.add(liquidity_minted);

        require(token.transferFrom(origin, address(this), token_amount));

        emit LiquidityChanged(oldLiq, totalLiquidity, isSH);

        return liquidity_minted;
    }

    function getValuesLiqWithdraw(
        address investor,
        uint256 liq,
        bool isSH
    ) public view returns (uint256, uint256) {
        IWStaked stk = getSTK(isSH);

        if (!stk.StakeExist(investor)) {
            return (0, 0);
        }

        uint256 inv;

        (inv, , ) = stk.getStake(investor);

        if (liq > inv) {
            return (0, 0);
        }

        uint256 eth_amount = liq.mul(_coin_reserve).div(totalLiquidity);
        uint256 token_amount =
            liq.mul(token.balanceOf(address(this))).div(totalLiquidity);
        return (eth_amount, token_amount);
    }

    function getMaxValuesLiqWithdraw(address investor, bool isSH)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IWStaked stk = getSTK(isSH);

        if (!stk.StakeExist(investor) || totalLiquidity == 0) {
            return (0, 0, 0);
        }

        uint256 token_reserve = token.balanceOf(address(this));

        uint256 inv;

        (inv, , ) = stk.getStake(investor);

        uint256 eth_amount = inv.mul(_coin_reserve).div(totalLiquidity);
        uint256 token_amount = inv.mul(token_reserve).div(totalLiquidity);
        return (inv, eth_amount, token_amount);
    }

    function _withdrawFunds(
        address account,
        uint256 liquid,
        bool isSH
    ) internal returns (uint256, uint256) {
        IWStaked stk = getSTK(isSH);

        require(stk.StakeExist(account), "1");

        uint256 inv_liq;

        (inv_liq, , ) = stk.getStake(account);

        require(liquid <= inv_liq, "2");

        uint256 token_reserve = token.balanceOf(address(this));

        uint256 eth_amount = liquid.mul(_coin_reserve).div(totalLiquidity);

        uint256 token_amount = liquid.mul(token_reserve).div(totalLiquidity);

        require(eth_amount <= getMyCoinBalance(), "3");

        require(token_amount <= getMyTokensBalance(), "4");

        stk.substractFromStake(account, liquid);

        uint256 oldLiq = totalLiquidity;

        totalLiquidity = totalLiquidity.sub(liquid);

        address(uint160(account)).transfer(eth_amount);

        _coin_reserve = getMyCoinBalance(); // address(this).balance;

        if (isSH) {
            require(token.transfer(_woopSharedFunds, token_amount));
        } else {
            require(token.transfer(account, token_amount));
        }

        emit LiquidityWithdraw(
            account,
            eth_amount,
            token_amount,
            totalLiquidity,
            isSH
        );
        emit LiquidityChanged(oldLiq, totalLiquidity, isSH);
        return (eth_amount, token_amount);
    }

    function WithdrawLiquidity(uint256 liquid, bool isSH)
        external
        nonReentrant
        returns (uint256, uint256)
    {
        require(!isPaused(), "1");

        require(totalLiquidity > 0, "2");

        return _withdrawFunds(_msgSender(), liquid, isSH);
    }
}
