// SPDX-License-Identifier: MIT

// j'ai préféré calculer le ou les gagnants au fur et à mesure mais on peut aussi lancer un calcul avec une boucle type FOR à la fin.
// Winners est un tableau d'entiers car il peut y avoir plusieurs gagnants.

pragma solidity 0.8.11;
 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
 
contract Voting is Ownable {

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

WorkflowStatus public status = WorkflowStatus.VotesTallied ;

mapping (address => Voter) public profil; // mettre private si on ne veut pas que les votes soient publics, y compris ci-dessous.
Proposal[] public propositions;

event VoterRegistered(address voterAddress); 
event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
event ProposalRegistered(uint proposalId);
event Voted (address voter, uint proposalId);


uint NombreProp; 
uint Max;
uint[] private winners; //le gagnant ne s'affiche qu'à la fin, cependant le tableau public "propositions" permet à tout moment de connaître le nombre de voix d'une proposition; ce choix est évidemment discutable et modifiable.
uint[] public Winners;

// Etape 0: l'administrateur (et lui seul) peut modifier le statut


function changeStatus(WorkflowStatus newStatus) public { // ou public onlyOwner { et on supprime la ligne suivante mais alors le message est celui specifie dans Ownable
    require (msg.sender == owner(), "Seul l'administrateur peut modifier le statut"); 
    emit WorkflowStatusChange(status, newStatus);
    if (newStatus == WorkflowStatus.RegisteringVoters) {
        NombreProp = 0;
        delete propositions;
        Max = 0;
        delete winners ;
        delete Winners ; // on efface les propositions et les gagnants au début de la procédure.
    }
    if (newStatus == WorkflowStatus.VotesTallied) {
        Winners = winners ; // on publie les résultats.
    }

    status = newStatus; 
}//modif possible: imposer que l'administrateur ne puisse passer qu'au statut suivant et pas à un autre

// Etape 1: Enregistrement des votants

function Register(address voterAddress) public  { // ou public onlyOwner { et on supprime la ligne suivante
    require (msg.sender == owner(), "seul l'administrateur peut enregistrer un votant");
    require (status == WorkflowStatus.RegisteringVoters , "la phase d'enregistrement est terminee ou n'a pas commence"); // heu on ne peut pas mettre d'accent dans les strings 
    profil[voterAddress].isRegistered = true;
    emit VoterRegistered(voterAddress);
}

// Etape 2: Enregistrement des Propositions 

function RegisterProposal(string memory prop) public {  
    require (profil[msg.sender].isRegistered == true, "vous ne pouvez soumettre votre proposition car vous n'etes pas enregistre en tant que votant");
    require (status == WorkflowStatus.ProposalsRegistrationStarted , "la phase d'enregistrement des propositions est terminee ou n'a pas commence");  
    ++ NombreProp ; // ? NombreProp +=1 marcherait ou pas ? La phrase des Docs qui fait peur:  a++ and a-- are equivalent to a += 1 / a -= 1 but the expression itself still has the previous value of a
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
    require (profil[msg.sender].hasVoted == false, "vous avez deja vote !");
    ++propositions[PropId-1].voteCount;  
    if (propositions[PropId-1].voteCount == Max) {
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

function getWinner() public view returns (uint[] memory) {  
    require (status == WorkflowStatus.VotesTallied , "le vote n'est pas termine et n'a peut-etre pas commence");  
    return Winners ;  // le tableau public de propositions permet à tous de vérifier les détails de la ou des propositions gagnantes: string associé, nombre de votes.
}

}

