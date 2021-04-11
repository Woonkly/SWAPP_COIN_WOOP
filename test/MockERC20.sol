// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/ERC20.sol";

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
