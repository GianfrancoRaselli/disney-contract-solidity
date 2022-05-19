// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";


contract Disney {

  using SafeMath for uint;


  // ---------------- DECLARACIONES INICIALES ----------------

  // direccion de disney (owner del contrato)
  address payable public owner = payable(msg.sender);

  // instancia del contrato token
  ERC20Basic internal token;

  // precio de 1 token en weis
  uint public precioToken;

  // estructura de datos para almacenar a los clientes de disney
  struct Cliente {
    uint tokensComprados;
    string[] historialAtracciones;
  }

  // mapping para el registro de clientes
  mapping(address => Cliente) public clientes;


  modifier onlyOwner() {
    // requiere que la direccion del ejecutor de la funcion sea igual al owner del contrato
    require(msg.sender == owner, 'No tienes permiso para acceder a esta funcion');
    _;
  }


  constructor(uint _precioToken) {
    token = new ERC20Basic(10000);
    precioToken = _precioToken;
  }


  // ---------------- GESTION DE TOKENS ----------------

  // funcion para establecer el precio de un token
  function precioTokens(uint _numTokens) internal view returns (uint) {
    // conversion de tokens a weis
    return _numTokens.mul(precioToken);
  }

  // funcion para comprar tokens en disney y disfrutar de las atracciones
  function comprarTokens(uint _numTokens) public payable {
    // establecer el precio de los tokens
    uint coste = precioTokens(_numTokens);

    // se evalua el dinero que cliente paga por los tokens
    require(msg.value >= coste, "La cantidad de weis enviada es insuficiente");

    // diferencia de lo que el cliente paga
    uint returnValue = msg.value.sub(coste);

    // retornar la diferencia de weis al cliente
    payable(msg.sender).transfer(returnValue);

    // validacion del numero de tokens disponibles
    uint balance = token.balanceOf(address(this));
    require(_numTokens <= balance, "Compra menos tokens");

    // se transfiere el numero de tokens al cliente
    token.transfer(msg.sender, _numTokens);

    // registro de tokens comprados
    clientes[msg.sender].tokensComprados.add(_numTokens);
  }

  // funcion para visualizar el numero de tokens restantes de un cliente
  function misTokens() public view returns (uint) {
    return token.balanceOf(msg.sender);
  }

  // funcion que permita a disney generar mas tokens
  function generarNuevosTokens(uint _numTokens) public onlyOwner() {
    token.increaseTotalSupply(_numTokens);
  }


  // ---------------- GESTION DE DISNEY ----------------

  // estructura de la atraccion
  struct Atraccion {
    string nombre;
    uint precio;
    bool estado;
  }

  // mapping para relacionar un nombre de una atraccion con una estructura de datos de la atraccion
  mapping(string => Atraccion) public atracciones;

  // array para almacenar el nombre de las atracciones
  string[] public nombreAtracciones;


  // eventos
  event disfrutaAtraccion(string, uint, address);
  event nuevaAtraccion(string, uint);
  event bajaAtraccion(string);


  // crear nuevas atracciones para disney (solo ejecutable por disney)
  function agregarNuevaAtraccion(string memory _nombreAtraccion, uint _precio) public onlyOwner() {
    // creacion de una atraccion en disney
    atracciones[_nombreAtraccion] = Atraccion(_nombreAtraccion, _precio, true);

    // almacenamiento en un array del nombre de la atraccion
    nombreAtracciones.push(_nombreAtraccion);

    // emision del evento para la nueva atraccion
    emit nuevaAtraccion(_nombreAtraccion, _precio);
  }

  // dar de baja a las atracciones en disney
  function darDeBajaAtraccion(string memory _nombreAtraccion) public onlyOwner() {
    // el estado de la atraccion para a false => no estara mas en uso
    atracciones[_nombreAtraccion].estado = false;

    // emision del evento para la baja de la atraccion
    emit bajaAtraccion(_nombreAtraccion);
  }

  // visualizar las atracciones de disney
  function verAtracciones() public view returns (string[] memory) {
    return nombreAtracciones;
  }

  // funcion para subirse a una atraccion de disney y pagar en tokens
  function subirseAtraccion(string memory _nombreAtraccion) public {
    // precio de la atraccion (en tokens)
    uint tokensAtraccion = atracciones[_nombreAtraccion].precio;

    // verificar el estado de la atraccion (si esta disponble para su uso)
    require(atracciones[_nombreAtraccion].estado, "La atraccion no esta disponible en estos momentos");

    // verifica el numero de tokens que tiene el cliente para subirse a la atraccion
    require(tokensAtraccion <= token.balanceOf(msg.sender), "Necesitas mas tokens para subirte a esta atraccion");

    // el cliente paga la atraccion en tokens
    token.autoTransfer(msg.sender, tokensAtraccion);

    // almacenamiento en el historial de atracciones del cliente
    clientes[msg.sender].historialAtracciones.push(_nombreAtraccion);

    // emision del evento para disfrutar de la atraccion
    emit disfrutaAtraccion(_nombreAtraccion, tokensAtraccion, msg.sender);
  }

  // visualizacion del historial completo de atracciones disfrutadas por un cliente
  function historialDeAtracciones() public view returns (string[] memory) {
    return clientes[msg.sender].historialAtracciones;
  }

  // funcion para que un cliente de disney pueda devolver tokens
  function devolverTokens(uint _numTokens) public {
    // el numero de tokens a devolver es positivo
    require(_numTokens > 0, "Necesitas devolver una cantidad positiva de tokens");

    // el usuario debe tener el numero de tokens que desea devolver
    require(_numTokens <= token.balanceOf(msg.sender), "No tienes los tokens que deseas devolver");

    // el cliente devuelve los tokens
    token.autoTransfer(msg.sender, _numTokens);

    // devolucion de los weis al cliente
    payable(msg.sender).transfer(_numTokens.mul(precioToken));
  }

}
