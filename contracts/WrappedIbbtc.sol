//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "../deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../deps/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./ICoreOracle.sol";

/*
    Wrapped Interest-Bearing Bitcoin (Non-Ethereum mainnet variant)
*/
contract WrappedIbbtc is Initializable, ERC20Upgradeable {
    address public governance;
    address public pendingGovernance;
    ERC20Upgradeable public ibbtc; 

    ICoreOracle public oracle;

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
        require(msg.sender == address(oracle), "onlyOracle");
        _;
    }

    function initialize(address _governance, address _ibbtc, address _oracle) public initializer {
        __ERC20_init("Wrapped Interest-Bearing Bitcoin", "wibBTC");
        governance = _governance;
        oracle = ICoreOracle(_oracle);
        ibbtc = ERC20Upgradeable(_ibbtc);

        emit SetOracle(_oracle);
    }

    /// ===== Permissioned: Governance =====
    function setPendingGovernance(address _pendingGovernance) external onlyGovernance {
        pendingGovernance = _pendingGovernance;
        emit SetPendingGovernance(pendingGovernance);
    }

    function setOracle(address _oracle) external onlyGovernance {
        oracle = ICoreOracle(_oracle);
        emit SetOracle(_oracle);
    }

    /// ===== Permissioned: Pending Governance =====
    function acceptPendingGovernance() external onlyPendingGovernance {
        governance = pendingGovernance;
        emit AcceptPendingGovernance(pendingGovernance);
    }

    /// ===== Permissionless Calls =====

    /// @dev Deposit ibBTC to mint wibBTC shares
    function mint(uint256 _shares) external {
        require(ibbtc.transferFrom(_msgSender(), address(this), _shares));
        _mint(_msgSender(), _shares);
    }

    /// @dev Redeem wibBTC for ibBTC. Denominated in shares.
    function burn(uint256 _shares) external {
        _burn(_msgSender(), _shares);
        require(ibbtc.transfer(_msgSender(), _shares));
    }

    ///// ===== View Methods =====

    /// @dev Current pricePerShare read live from oracle
    function pricePerShare() public view virtual returns (uint256) {
        return oracle.pricePerShare();
    }

    /// @dev Wrapped ibBTC shares of account
    function sharesOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @dev Current account shares * pricePerShare
    function balanceOf(address account) public view override returns (uint256) {
        return sharesOf(account).mul(pricePerShare()).div(1e18);
    }

    /// @dev Total wrapped ibBTC shares
    function totalShares() public view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Current total shares * pricePerShare
    function totalSupply() public view override returns (uint256) {
        return totalShares().mul(pricePerShare()).div(1e18);
    }

    function balanceToShares(uint256 balance) public view returns (uint256) {
        return balance.mul(1e18).div(pricePerShare());
    }

    function sharesToBalance(uint256 shares) public view returns (uint256) {
        return shares.mul(pricePerShare()).div(1e18);
    }
}
