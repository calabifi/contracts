// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "./CalabiLP.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";
import "./interfaces/IERC20Calabi.sol";
import "./interfaces/ICalabiFactory.sol";
import "./interfaces/ICalabiCallee.sol";

contract CalabiPair is CalabiLP {
    using SafeMathCalabi for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    struct SwapVariables {
        uint112 _reserve0;
        uint112 _reserve1;
        uint256 balance0;
        uint256 balance1;
        uint256 amount0In;
        uint256 amount1In;
    }

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "CalabiPair: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns(
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "CalabiPair: TRANSFER_FAILED"
        );
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "CalabiPair: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= uint112(-1) && balance1 <= uint112(-1),
            "CalabiPair: OVERFLOW"
        );

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if(timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast +=
                uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }


    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1)
        private
        returns(bool feeOn)
    {
        address feeTo = ICalabiFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings

        if(feeOn) {
            if(_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if(rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if(liquidity > 0) 
                        _mint(feeTo, liquidity);
                }
            }
        } else if(_kLast != 0) {
            kLast = 0;
        }
    }

    
    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns(uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20Calabi(token0).balanceOf(address(this));
        uint256 balance1 = IERC20Calabi(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if(_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / _reserve0,
                amount1.mul(_totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "CalabiPair: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if(feeOn) 
            kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date

        emit Mint(msg.sender, amount0, amount1);
    }


    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to)
        external
        lock
        returns(uint256 amount0, uint256 amount1)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20Calabi(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20Calabi(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "CalabiPair: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Calabi(_token0).balanceOf(address(this));
        balance1 = IERC20Calabi(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if(feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "CalabiPair: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        SwapVariables memory vars = SwapVariables(0, 0, 0, 0, 0, 0);
        (vars._reserve0, vars._reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < vars._reserve0 && amount1Out < vars._reserve1,
            "CalabiPair: INSUFFICIENT_LIQUIDITY"
        );

        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "CalabiPair: INVALID_TO");
            if(amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if(amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if(data.length > 0)
                ICalabiCallee(to).uniswapV2Call(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            vars.balance0 = IERC20Calabi(_token0).balanceOf(address(this));
            vars.balance1 = IERC20Calabi(_token1).balanceOf(address(this));
        }
        vars.amount0In = vars.balance0 > vars._reserve0 - amount0Out
            ? vars.balance0 - (vars._reserve0 - amount0Out)
            : 0;
        vars.amount1In = vars.balance1 > vars._reserve1 - amount1Out
            ? vars.balance1 - (vars._reserve1 - amount1Out)
            : 0;
        require(
            vars.amount0In > 0 || vars.amount1In > 0,
            "CalabiPair: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1} - Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = vars.balance0.mul(10000).sub(
                vars.amount0In.mul(25)
            );
            uint256 balance1Adjusted = vars.balance1.mul(10000).sub(
                vars.amount1In.mul(25)
            );
            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                    uint256(vars._reserve0).mul(vars._reserve1).mul(10000**2),
                "CalabiPair: K"
            );
        }

        _update(vars.balance0, vars.balance1, vars._reserve0, vars._reserve1);
        emit Swap(
            msg.sender,
            vars.amount0In,
            vars.amount1In,
            amount0Out,
            amount1Out,
            to
        );
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(
            _token0,
            to,
            IERC20Calabi(_token0).balanceOf(address(this)).sub(reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20Calabi(_token1).balanceOf(address(this)).sub(reserve1)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20Calabi(token0).balanceOf(address(this)),
            IERC20Calabi(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}
