pragma solidity ^0.5.12;
 
contract Crowdsale {
    //Audit: manque l'import de la lib SafeMath
   using SafeMath for uint256;
 
   address public owner; // the owner of the contract
   address public escrow; // wallet to collect raised ETH
   uint256 public savedBalance = 0; // Total amount raised in ETH
   mapping (address => uint256) public balances; // Balances in incoming Ether
   //Audit: L'initialisation doit se faire dans la méthode constructor sans le mot-clé function
   // Initialization
   function Crowdsale(address _escrow) public{
       //Audit: Tx.origin ne doit pas être utilisée pour determiner le owner. il faut utiliser msg.sender
       owner = tx.origin;
       //Audit: il ne faudrait pas utiliser un wallet externe, en moins d'être sûr à 100% de sa gestion et sécurité
       //Audit: il est plus sûr de stocker dans une variable (stockage) interne au smart contract
       // add address of the specific contract
       escrow = _escrow;
   }
  
   // function to receive ETH
   function() public {
       balances[msg.sender] = balances[msg.sender].add(msg.value);
       savedBalance = savedBalance.add(msg.value);
       //Audit: il faut s'assurer que le transfert est succès, sinon rollback. on utilise le boolean renvoyer par send
       escrow.send(msg.value);
   }
  
   // refund investisor
   //Audit: le pattern Check-Effects-Interraction n'est pas respecté dans cette méthode.
   //Audit: Re-entrancy : msg.sender peut retirer plus que ce qu'il a investi =>il peut retirer tous les ethers du smart contract
   function withdrawPayments() public{
       //Audit: la variable payee est initule et augmente l'utilisation de la mémoire => +gas
       address payee = msg.sender;
       uint256 payment = balances[payee];
       //Audit: il faut vérifier la balance avant send
       payee.send(payment);
       //Audit: il faut vérifier le statut de l'envoi avec require
       savedBalance = savedBalance.sub(payment);
       //Audit: les effets doivent être intervenir avant send
       balances[payee] = 0;
   }
}