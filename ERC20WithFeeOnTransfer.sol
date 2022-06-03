// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MyToken is Context, ERC20, Ownable {

    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _balances;
    uint256 public _feePecentage; 
    uint256 constant _fullPercentage = 10000;
    address public _fund;
    address public MANAGER;

   
    event FundModified(address indexed previousFund, address indexed newFund);
    event ManagerModified(address indexed previousFund, address indexed newFund);
    event FeeModified(uint256 indexed newFeePercentage);

    constructor(address fundAddress, address managerAddress, uint256 totalSupply) ERC20("MyTokenName", "SYMBOL") {  
        _fund = fundAddress;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[fundAddress] = true;
        _mint(fundAddress, totalSupply);
        _balances[fundAddress] = totalSupply;
        MANAGER = managerAddress;
    }

    modifier onlyManager() {
        require(MANAGER == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _transfer(address from, address to, uint256 amount) internal override{
        require(amount > 0, "Transfer amount must be greater than zero");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 toRecipientAmount = amount;
        if (!_isExcludedFromFee[to] && !_isExcludedFromFee[from]){
            uint256 amountToFund = _feePecentage * amount / _fullPercentage;
            toRecipientAmount -= amountToFund;
            _balances[_fund] += amountToFund;
            emit Transfer(from, _fund, amountToFund);
        }
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += toRecipientAmount;

        emit Transfer(from, to, toRecipientAmount);
        _afterTokenTransfer(from, to, amount);
    }

    function changeFundAddress(address newFundAddress) external onlyManager(){
        _fund = newFundAddress;
        emit FundModified(_fund, newFundAddress);
    }

    function changeManagerAddress(address newManagerAddress) external onlyManager(){
        MANAGER = newManagerAddress;
        emit ManagerModified(MANAGER, newManagerAddress);
    }

    function modifyFeePercentage(uint256 newFeePercentage) external onlyManager(){
        _feePecentage = newFeePercentage;
        emit FeeModified(newFeePercentage);
    }

    function excludeFromFees(address enableAddress) external onlyManager(){
        _isExcludedFromFee[enableAddress] == true;
    }

    function includeFromFees(address disableAddress) external onlyManager(){
        _isExcludedFromFee[disableAddress] == false;
    }

    function isExcludedFromFee(address checkAddress) external view returns(bool) {
        return _isExcludedFromFee[checkAddress];
    }
}