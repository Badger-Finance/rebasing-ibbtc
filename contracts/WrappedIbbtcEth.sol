//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "../deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../deps/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../deps/@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./ICore.sol";

/*
    Wrapped Interest-Bearing Bitcoin (Ethereum mainnet variant)
*/
contract WrappedIbbtcEth is Initializable, ERC20Upgradeable, PausableUpgradeable {
    address public governance;
    address public pendingGovernance;
    IERC20Upgradeable public ibbtc;
    
    ICore public core;

    uint256 public pricePerShare;
    uint256 public lastPricePerShareUpdate;

    event SetCore(address core);
    event SetPricePerShare(uint256 pricePerShare, uint256 updateTimestamp);
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

    function initialize(address _governance, address _ibbtc, address _core) public initializer {
        require(msg.sender == 0xDA25ee226E534d868f0Dd8a459536b03fEE9079b); // dev: only verified deployer
        __ERC20_init("Wrapped Interest-Bearing Bitcoin", "wibBTC");
        governance = _governance;
        core = ICore(_core);
        ibbtc = IERC20Upgradeable(_ibbtc);

        updatePricePerShare();

        emit SetCore(_core);
    }

    /// ===== Permissioned: Governance =====
    function setPendingGovernance(address _pendingGovernance) external onlyGovernance {
        require(_pendingGovernance != governance);
        pendingGovernance = _pendingGovernance;
        emit SetPendingGovernance(pendingGovernance);
    }

    /// @dev The ibBTC token is technically capable of having it's Core contract changed via governance process. This allows the wrapper to adapt.
    /// @dev This function should be run atomically with setCore() on ibBTC if that eventuality ever arises.
    function setCore(address _core) external onlyGovernance {
        core = ICore(_core);
        emit SetCore(_core);
    }

    function pause() external onlyGovernance {
        _pause();
    }

    function unpause() external onlyGovernance {
        _unpause();
    }

    /// ===== Permissioned: Pending Governance =====
    function acceptPendingGovernance() external onlyPendingGovernance {
        governance = pendingGovernance;
        pendingGovernance = address(0);
        emit AcceptPendingGovernance(governance);
    }

    /// ===== Permissionless Calls =====

    /// @dev Update live ibBTC price per share from core
    /// @dev We cache this to reduce gas costs of mint / burn / transfer operations.
    /// @dev Update function is permissionless, and must be updated at least once every X time as a sanity check to ensure value is up-to-date
    function updatePricePerShare() public whenNotPaused returns (uint256) {
        pricePerShare = core.pricePerShare();
        lastPricePerShareUpdate = block.timestamp;

        emit SetPricePerShare(pricePerShare, lastPricePerShareUpdate);
    }

    /// @dev Deposit ibBTC to mint wibBTC shares
    function mint(uint256 _shares) external whenNotPaused {
        if (_shares == 0) {
            return;
        }
        require(ibbtc.transferFrom(_msgSender(), address(this), _shares));
        _mint(_msgSender(), _shares);
    }

    /// @dev Redeem wibBTC for ibBTC. Denominated in shares.
    function burn(uint256 _shares) external whenNotPaused {
        if (_shares == 0) {
            return;
        }
        _burn(_msgSender(), _shares);
        require(ibbtc.transfer(_msgSender(), _shares));
    }

    /// ===== ERC20Upgradeable Overrides =====
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        /// The _balances mapping represents the underlying ibBTC shares ("non-rebased balances")
        /// Some naming confusion emerges due to maintaining original ERC20 var names

        if (amount == 0) {
            return true;
        }

        uint256 amountInShares = balanceToShares(amount);

        _transfer(sender, recipient, amountInShares);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        /// The _balances mapping represents the underlying ibBTC shares ("non-rebased balances")
        /// Some naming confusion emerges due to maintaining original ERC20 var names

        if (amount == 0) {
            return true;
        }

        uint256 amountInShares = balanceToShares(amount);

        _transfer(_msgSender(), recipient, amountInShares);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - `amount` must be in shares
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, sharesToBalance(amount));
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, balanceToShares(amount));
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), balanceToShares(amount));
    }

    /// ===== View Methods =====

    /// @dev Wrapped ibBTC shares of account
    function sharesOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @dev Current account shares * pricePerShare
    function balanceOf(address account) public view override returns (uint256) {
        return sharesOf(account).mul(pricePerShare).div(1e18);
    }

    /// @dev Total wrapped ibBTC shares
    function totalShares() public view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Current total shares * pricePerShare
    function totalSupply() public view override returns (uint256) {
        return totalShares().mul(pricePerShare).div(1e18);
    }

    function balanceToShares(uint256 balance) public view returns (uint256) {
        return balance.mul(1e18).div(pricePerShare);
    }

    function sharesToBalance(uint256 shares) public view returns (uint256) {
        return shares.mul(pricePerShare).div(1e18);
    }
}
