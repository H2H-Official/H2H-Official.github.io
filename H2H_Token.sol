// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title From Hacker to Hacker (H2H)
 * @dev A privacy-conscious, community-driven token with built-in 
 * deflationary mechanics and a dedicated growth fund for hacker bounties.
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract HackerToHacker is IERC20 {
    string public constant name = "From Hacker to Hacker";
    string public constant symbol = "H2H";
    uint8 public constant decimals = 18;
    
    // 21,000,000 Total Supply
    uint256 private _totalSupply = 21000000 * 10**uint256(decimals);
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFees;

    address public owner;
    address public developmentWallet; // Fund for upgrades/hackers
    
    // 3% Total Tax: 1% Burn, 2% Growth Fund
    uint256 public constant BURN_FEE = 1; 
    uint256 public constant GROWTH_FEE = 2;

    // Anti-Whale: No one can hold more than 2% of supply (420,000 H2H)
    uint256 public maxWalletBalance = (_totalSupply * 2) / 100;

    constructor(address _devWallet) {
        owner = msg.sender;
        developmentWallet = _devWallet;
        
        // Exclude owner and dev wallet from fees and limits
        isExcludedFromFees[owner] = true;
        isExcludedFromFees[developmentWallet] = true;
        
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "H2H: Only owner");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "H2H: transfer amount exceeds allowance");
        _allowances[sender][msg.sender] = currentAllowance - amount;
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "H2H: transfer from zero address");
        require(recipient != address(0), "H2H: transfer to zero address");
        require(amount > 0, "H2H: amount must be > 0");

        // Anti-Whale Check
        if (!isExcludedFromFees[recipient]) {
            require(_balances[recipient] + amount <= maxWalletBalance, "H2H: Exceeds max wallet limit");
        }

        uint256 transferAmount = amount;

        // Apply Fees (if not excluded)
        if (!isExcludedFromFees[sender] && !isExcludedFromFees[recipient]) {
            uint256 burnAmount = (amount * BURN_FEE) / 100;
            uint256 growthAmount = (amount * GROWTH_FEE) / 100;
            
            // 1% Burn: Reduce Total Supply
            _totalSupply -= burnAmount;
            emit Transfer(sender, address(0), burnAmount);
            
            // 2% Growth: Send to Dev Wallet
            _balances[developmentWallet] += growthAmount;
            emit Transfer(sender, developmentWallet, growthAmount);
            
            transferAmount = amount - burnAmount - growthAmount;
        }

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        emit Transfer(sender, recipient, transferAmount);
    }
}
