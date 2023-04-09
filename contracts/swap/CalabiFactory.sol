// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "./interfaces/ICalabiFactory.sol";
import "./CalabiPair.sol";

contract CalabiFactory is ICalabiFactory {
    bytes public constant creationCode = type(CalabiPair).creationCode; 
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(CalabiPair).creationCode));

    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(address feeToSetter_) public {
        feeToSetter = feeToSetter_;
    }

    function allPairsLength() external view override returns(uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        override
        returns(address pair)
    {
        require(tokenA != tokenB, "[Tau Swap]: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "[Tau Swap]: ZERO_ADDRESS");
        require(
            getPair[token0][token1] == address(0),
            "[Tau Swap]: PAIR_EXISTS"
        ); // single check is sufficient

        bytes memory bytecode = creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        CalabiPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "[Tau Swap]: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, "[Tau Swap]: FORBIDDEN");
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "[Tau Swap]: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
