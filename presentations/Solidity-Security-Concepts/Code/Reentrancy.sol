pragma solidity ^0.8.0;

//@title Kontrakt za koriscenje transakcija
//@author Emin
//@notice Kontrakt za dizanje i depozitanje novca
//@dev Kod je ranjiv na reentrancy
//@custom:transactions Primer ranjivog kontrakta na Reentrancy Napad
contract Transactions {

    mapping(address => uint256) private balances; /// mapiranje addresa i njihovih balansa na walletu
    mapping(address => bool) private locked; /// mapiranje addresa sa booleanom koji ce nam dati informacije da li je vec neka transakcija tok racuna u toku


    ///@notice Funkcija za podizanje ethera na odredjeni wallet
    ///@dev Funkcija ranjiva na Reentrancy napad
    ///@param amount predstavlja kolicinu ethera za podizanje
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance"); /// Proveravanje da li korisnik ima dovoljnu kolicinu ethera na racunu
        /// Slanje ethera na callerovu adresu (msg.sender) i uzima vrednost da li je uspesno ili ne
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed"); /// Provera da li je transakcija uspesna

        balances[msg.sender] -= amount; /// Oduzimanje whithdrawanog ethera sa balansa
    }

    ///@notice Funkcija za podizanje ethera na odredjeni wallet
    ///@dev Funkcija koja je zasticena od Reentrancy napada
    ///@param amount predstavlja kolicinu ethera za podizanje
    ///@custom:withdraw Funkcija je zasticena od Reentrancy napada koristeci CEI pattern-a
    function fixedWithdraw(uint256 amount) external {
        /// Checks
        require(balances[msg.sender] >= amount, "Insufficient balance");///Proverava da li korisnik ima dovoljno ethera za withdrawal
        require(!locked[msg.sender], "Withdrawal in progress");///Provera da li je vec neka transakcija u toku na ovoj adresi

    
        locked[msg.sender] = true;///// Setovanje reentrancy lock-a

        // Effects
        balances[msg.sender] -= amount; ///Oduzimanje ethera sa korisnikovog balanca

        // Interactions
        /// Slanje ethera na callerovu adresu (msg.sender) i uzima vrednost da li je uspesno ili ne
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");///Provera da li je transakcija uspesna

        locked[msg.sender] = false;///Setuje false na mapiranje korisnicke adrese pomocu koje se proverava da li je neka transakcija u toku
    }

    /// Openzeppelin ReentrancyGuard

}