// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
    
    uint256 private _totalSupply = 21000000 * 10**uint256(decimals);
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFees;

    address public owner;
    address public developmentWallet;
    
    uint256 public constant BURN_FEE = 1; 
    uint256 public constant GROWTH_FEE = 2;
    uint256 public maxWalletBalance = (_totalSupply * 2) / 100;

    // New Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DevelopmentWalletUpdated(address indexed previousWallet, address indexed newWallet);
    event FeeExclusionUpdated(address indexed account, bool excluded);

    constructor(address _devWallet) {
        owner = msg.sender;
        developmentWallet = _devWallet;
        
        isExcludedFromFees[owner] = true;
        isExcludedFromFees[developmentWallet] = true;
        isExcludedFromFees[address(this)] = true;
        
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "H2H: Only owner");
        _;
    }

    // --- ADMINISTRATIVE FUNCTIONS ---
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "H2H: zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function updateDevelopmentWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "H2H: zero address");
        emit DevelopmentWalletUpdated(developmentWallet, newWallet);
        developmentWallet = newWallet;
    }
    
    function setExcludedFromFees(address account, bool excluded) external onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit FeeExclusionUpdated(account, excluded);
    }

    // --- STANDARD ERC20 FUNCTIONS ---

    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address _owner, address spender) public view override returns (uint256) { return _allowances[_owner][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "H2H: transfer amount exceeds allowance");
        _allowances[sender][msg.sender] = currentAllowance - amount;
        return true;
    }

    // --- FIXED TRANSFER LOGIC ---
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "H2H: transfer from zero address");
        require(recipient != address(0), "H2H: transfer to zero address");
        require(amount > 0, "H2H: amount must be > 0");
        require(_balances[sender] >= amount, "H2H: insufficient balance");

        if (!isExcludedFromFees[recipient]) {
            require(_balances[recipient] + amount <= maxWalletBalance, "H2H: Exceeds max wallet limit");
        }

        // Deduct full amount from sender
        _balances[sender] -= amount;

        uint256 transferAmount = amount;

        if (!isExcludedFromFees[sender] && !isExcludedFromFees[recipient]) {
            uint256 burnAmount = (amount * BURN_FEE) / 100;
            uint256 growthAmount = (amount * GROWTH_FEE) / 100;
            
            _totalSupply -= burnAmount;
            emit Transfer(sender, address(0), burnAmount);
            
            _balances[developmentWallet] += growthAmount;
            emit Transfer(sender, developmentWallet, growthAmount);
            
            transferAmount = amount - burnAmount - growthAmount;
        }

        // Credit net amount to recipient
        _balances[recipient] += transferAmount;
        emit Transfer(sender, recipient, transferAmount);
    }
}
