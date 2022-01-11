// j'ai préféré calculer le ou les gagnants au fur et à mesure mais je pense qu'on attendait un calcul avec une boucle type FOR à la fin
// Pour moi Winner est un tableau d'entiers car il peut y avoir plusieurs gagnants

pragma solidity 0.8.11;
 
import "./ownable.sol";  // ou sinon import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol" 
// j'ai mis ./ et non ../ car sur Remix les 2 contrats sont au même niveau
 
contract Voting {

struct Voter {
bool isRegistered;
bool hasVoted;
uint votedProposalId;
}
struct Proposal {
string description;
uint voteCount;
}


enum WorkflowStatus {
RegisteringVoters,
ProposalsRegistrationStarted,
ProposalsRegistrationEnded,
VotingSessionStarted,
VotingSessionEnded,
VotesTallied
}

mapping (address => Voter) profil;
Proposal[] public propositions;

event VoterRegistered(address voterAddress); 
event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
event ProposalRegistered(uint proposalId);
event Voted (address voter, uint proposalId);


uint NombreProp; 
address _owner; // ? ça met des erreurs sinon, pourtant _owner est déclaré dans ownable.sol ?
uint Max;
uint[] private winners;
uint[] public Winners;

// Etape 0: l'administrateur peut modifier le statut

WorkflowStatus status;

function changeStatus(WorkflowStatus newStatus) public { // ? pourquoi pas avec un "return" ? Pourquoi erreur si on rajoute view ?
    require (msg.sender == _owner, "Seul l'administrateur peut modifier le statut"); 
    emit WorkflowStatusChange(status, newStatus);
    if (newStatus == WorkflowStatus.ProposalsRegistrationStarted) {
        NombreProp = 0;
    }
    if (newStatus == WorkflowStatus.VotingSessionStarted) {
        Max = 0;
        delete winners ;
        delete Winners ;
    }
    if (newStatus == WorkflowStatus.VotesTallied) {
        Winners = winners ;
    }

    status=newStatus; // et non pas status=workflowStatus.newstatus ?
}

// Etape 1: Enregistrement des votants

function Register(address voterAddress) public  {
    require (msg.sender == _owner, "seul l'administrateur peut enregistrer un votant");
    require (status == WorkflowStatus.RegisteringVoters , "la phase d'enregistrement est terminee ou n'a pas commence"); // heu on ne peut pas mettre d'accent dans les strings 
    profil[voterAddress].isRegistered = true;
    emit VoterRegistered(voterAddress);
}

// Etape 2: Enregistrement des Propositions 

function RegisterProposal(string memory prop) public { // plein d'erreurs si on met view
    require (profil[msg.sender].isRegistered == true, "vous ne pouvez soumettre votre proposition car vous n'etes pas enregistre en tant que votant");
    require (status == WorkflowStatus.ProposalsRegistrationStarted , "la phase d'enregistrement des propositions est terminee ou n'a pas commence");  
    ++ NombreProp ; // ? NombreProp +=1 marcherait ou pas ? : a++ and a-- are equivalent to a += 1 / a -= 1 but the expression itself still has the previous value of a
    Proposal memory newProp = Proposal(prop , 0);
    propositions.push(newProp) ;
    emit ProposalRegistered(NombreProp);
}

// Etape 3: Fin de le session d'enregistrement des propositions 
// Rien à Faire

// Etape 4: Votes

function RegisterVote(uint PropId) public {
    require (profil[msg.sender].isRegistered == true, "vous ne pouvez soumettre votre vote car vous n'etes pas enregistre en tant que votant");
    require (status == WorkflowStatus.VotingSessionStarted , "la phase d'enregistrement des votes est terminee ou n'a pas commence");  
    ++propositions[PropId-1].voteCount;  // je suppose que tableau[0] est le 1er élément du tableau, d'ou le -1
    if (propositions[PropId-1].voteCount == Max) { // si 
    winners.push(PropId) ;
    }
    if (propositions[PropId-1].voteCount > Max) {
    delete winners ;   
    Max = propositions[PropId-1].voteCount ;
    winners.push(PropId) ;
    }
    profil[msg.sender].hasVoted = true;
    profil[msg.sender].votedProposalId = PropId ;
    emit Voted(msg.sender , PropId);

}

// Etape 5: Fin de la session de vote
// Rien à Faire

// Etape 6: Comptabilisation des votes et publication du ou des gagnants

function getWinner() public returns (uint[] memory) {  // il y a un warning que je ne comprends pas
    require (status == WorkflowStatus.VotesTallied , "le vote n'est pas termine");  
    return Winners ; 
}

}

