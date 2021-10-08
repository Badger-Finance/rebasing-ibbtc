//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "../deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../deps/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract RebasingIbbtc is Initializable, ERC20Upgradeable {
    address public governance;
    address public pendingGovernance;
    ERC20Upgradeable public ibbtc; 
    address public oracle;
    uint256 public pricePerShare;

    event SetPricePerShare(uint256 pricePerShare);
    event SetOracle(address oracle);
    event SetPendingGovernance(address pendingGovernance);
    event AcceptPendingGovernance(address pendingGovernance);

    /// ===== Modifiers =====
    modifier onlyPendingGovernance() {
        require(msg.sender == pendingGovernance, "onlyPendingGovernance");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "onlyGovernance");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "onlyOracle");
        _;
    }

    function initialize(string memory name, string memory symbol, address _governance, address _ibbtc, address _oracle) public initializer {
        __ERC20_init(name, symbol);
        governance = _governance;
        oracle = _oracle;

        ibbtc = ERC20Upgradeable(_ibbtc);
    }

    /// ===== Permissioned: Governance =====
    function setOracle(address _oracle) external onlyGovernance {
        oracle = _oracle;
        emit SetOracle(oracle);
    }

    function setPendingGovernance(address _pendingGovernance) external onlyGovernance {
        pendingGovernance = _pendingGovernance;
        emit SetPendingGovernance(pendingGovernance);
    }

    /// ===== Permissioned: Pending Governance =====
    function acceptPendingGovernance() external onlyPendingGovernance {
        governance = pendingGovernance;
        emit AcceptPendingGovernance(pendingGovernance);
    }

    /// ===== Permissioned: Oracle =====
    function setPricePerShare(uint256 _pricePerShare) external onlyOracle {
        pricePerShare = _pricePerShare;
        emit SetPricePerShare(pricePerShare);
    }

    /// ===== Permissionless Calls =====

    /// @dev Transfer ibBTC to mint the equivalent number of ribBTC shares
    function mint(uint256 _shares) external {
        require(ibbtc.transferFrom(_msgSender(), address(this), _shares));
        _mint(_msgSender(), _shares);
    }

    function burn(uint256 _shares) external {
        _mint(_msgSender(), _shares);
        require(ibbtc.transfer(_msgSender(), _shares));
    }

    ///// ===== View Methods =====

    /// @dev Wrapped ibBTC shares of account
    function sharesOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @dev Current account shares * pricePerShare
    function balanceOf(address account) public view override returns (uint256) {
        sharesOf(account).mul(pricePerShare).div(1e18);
    }

    /// @dev Total wrapped ibBTC shares
    function totalShares() public view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Current total shares * pricePerShare
    function totalSupply() public view override returns (uint256) {
        return totalShares().mul(pricePerShare).div(1e18);
    }
}
