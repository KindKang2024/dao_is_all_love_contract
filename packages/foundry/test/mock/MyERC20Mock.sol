// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from
  "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract MyERC20Mock is ERC20, ERC20Permit, ERC165 {
  constructor(
    string memory name,
    string memory symbol,
    address initialAccount,
    uint256 initialBalance
  ) payable ERC20(name, symbol) ERC20Permit(name) {
    _mint(initialAccount, initialBalance);
  }

  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
  }

  function burn(address account, uint256 amount) public {
    _burn(account, amount);
  }

  function transferInternal(address from, address to, uint256 value) public {
    _transfer(from, to, value);
  }

  function approveInternal(
    address owner,
    address spender,
    uint256 value
  ) public {
    _approve(owner, spender, value);
  }

  // EIP-165 support
  function supportsInterface(
    bytes4 interfaceId
  ) public pure override returns (bool) {
    return interfaceId == 0x7965db0b // EIP-2612
      || interfaceId == 0x36372b07; // ERC20
  }
}
