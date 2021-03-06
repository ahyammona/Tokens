// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Context.sol";
import "./Ownable.sol";

contract BaseBEP20 is Context, Ownable {
     mapping(address => uint256) internal _balances;
     mapping(address => mapping(address => uint256)) internal _allowance;


     string internal _name;
     string internal _symbol;
      
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    )  {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * 10 **_decimals;
    }
    function name() public view virtual returns(string memory){
        return _name;
    }
   
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual returns(uint256){
        return _balances[account];
    }
    function approve(address spender, uint256 amount) public virtual returns(bool){
        _approve(_msgSender(),spender,amount);
        return true;
    }
    function allowance(address owner , address spender) public view virtual returns(uint256){
        return _allowance[owner][spender];
    }
    function transfer(address recipient, uint256 amount) public virtual returns(bool) {
        _transfer(_msgSender(),recipient,amount);
        return true;
    }
    function transferFrom( address sender, address recipient, uint256 amount) public virtual returns (bool){
        _transfer(sender,recipient,amount);
        uint256 currentAllowance = _allowance[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender,_msgSender(),currentAllowance - amount);
        return true;
    }
    function _transfer(address sender,address recipient,uint256 amount) internal virtual{
        require(sender != address(0), "BEP20: transfer from zero address");
        require(recipient != address(0), "BEP20: transfer to zero address");
        require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender,recipient,amount);
    }
    function _approve ( address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20 : approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}