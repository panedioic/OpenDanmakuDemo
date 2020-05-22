// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.4.24;


contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Coinbase(address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
}

contract ERC20Token is EIP20Interface {

    uint256 constant MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    
    mapping(address => bool) isAdmin;
    mapping(address => bool) isFrozen;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    // 1 ether about 1024 DMB.
    function deposit() public payable {
        coinbase(msg.sender, msg.value * 1000 / 1000000000);
    }

    function withdraw(uint amount) public payable{
        burn(msg.sender, amount);
        msg.sender.transfer(amount / 1000 * 1000000000);
    }
    
    function coinbase(address _to, uint256 _value) internal returns(bool success){
        require(balances[0x00] >= _value);
        balances[0x00] -= _value;
        balances[_to] += _value;
        emit Coinbase(_to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    function burn(address _from, uint256 _value) internal returns(bool success){
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[0x00] += _value;
        emit Burn(_from, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    function() public payable{}
}

contract OpenDanmakuDemo is ERC20Token {
    
    bool IS_TEST_MODE = true;
    
    struct DanmakuFile {
        bytes32 prevHash;
        
        bytes32 addrHash;
        uint32 thisBlock;
        uint8 strLen;
        uint16 updateDanmaku;
        bytes fileAddr;
    }
    
    struct DiffInfo {
        uint256 lastCheckBlock;
        uint256 totalRequest;
        uint256 currentDiff;
    }
    
    mapping(bytes20 => DanmakuFile) DanmakuPool;
    mapping(bytes20 => DiffInfo) DiffOf;
    mapping(address => bool) Registed;
    mapping(address => uint256) lastUpdateBlock;
    
    uint256 storageDiff; // Require (sha256(IpfsAddress, nonce) < Diff).
    uint256 registDiff; // Require (msg.sender xor cid[:160(bit)] < Diff).
    uint256 constant STANDARD_DIFF = 1 << 240;
    
    event Store(bytes20 indexed _cid, bytes FileAddr, bytes32 _hash);
    event Report(bytes20 indexed _cid, bytes32 _hash);
    
    constructor( string _name, string _symbol ) public {
        totalSupply = (1<<32) * 1000000000;           // Update total supply
        balances[0x00] = totalSupply;                     // Give the creator all initial tokens
        name = _name;                                           // Set the name for display purposes
        decimals = 9;                                   // Amount of decimals for display purposes
        symbol = _symbol;       
        
        isAdmin[msg.sender]=true;
        registDiff = (1 << 256) - 1; // Maximum of this value is 2 ^ 160 - 1.// Set the symbol for display purposes
    }
    
    function userRegister(bytes20 cid, bytes32 nonce) public {
        require(uint256(sha256(abi.encodePacked(msg.sender, cid, nonce))) < registDiff, "Unavailable nonce!");
        Registed[msg.sender] = true;
    }
    
    function userReport(bytes20 _cid, bytes32 _hash) public{
        emit Report(_cid, _hash);
    }
    
    //might be on ipfs, bittorrent swarm or even on a transaction.
    function storeDanmakuFile(bytes20 cid, uint8 strLen, uint16 updateDanmaku, bytes32 parentHash, bytes FileAddr, bytes12 nonce) public{
        require(Registed[msg.sender], "Please regist first! debug");
        require(uint256(sha256(abi.encodePacked( parentHash, nonce ))) < getStorageDiff(cid), "Uncorrect nonce!");
        
        bytes32 _hash = sha256(abi.encodePacked(FileAddr));
        emit Store(cid, FileAddr, _hash);
        DanmakuFile memory tmpFile = DanmakuPool[cid];
        
        if(uint32(block.number) == tmpFile.thisBlock){
            require(parentHash == tmpFile.prevHash, "Wrong parent!");
            require(updateDanmaku > tmpFile.updateDanmaku, "Unable to rewrite danmaku file on this block!");
            
            tmpFile.strLen = strLen;
            tmpFile.updateDanmaku = updateDanmaku;
            tmpFile.fileAddr = FileAddr;
            DanmakuPool[cid] = tmpFile;
        } else {
            require(parentHash == tmpFile.addrHash, "Wrong parent!");
            
            tmpFile.prevHash = parentHash;
            tmpFile.thisBlock = uint8(block.number);
            tmpFile.strLen = strLen;
            tmpFile.updateDanmaku = updateDanmaku;
            tmpFile.fileAddr = FileAddr;
            DanmakuPool[cid] = tmpFile;
        }
        coinbase(msg.sender, balances[0x00]>>36);
    }
    
    function getDanmakuFile(bytes20 cid) public view returns(uint8, uint16, bytes, bytes32){
        DanmakuFile memory tmpFile = DanmakuPool[cid];
        return (tmpFile.strLen, tmpFile.updateDanmaku, tmpFile.fileAddr, tmpFile.prevHash);
    }
    
    function getStorageDiff(bytes20 cid) public returns(uint256){
        if(IS_TEST_MODE){
            return MAX_UINT256;
        } else {
            DiffInfo memory tmp = DiffOf[cid];
            DiffOf[cid].totalRequest += 1;
            if(tmp.lastCheckBlock>>8 == block.number>>8){
                return tmp.currentDiff;
            } else {
                DiffOf[cid].lastCheckBlock = block.number;
                DiffOf[cid].currentDiff = STANDARD_DIFF / (DiffOf[cid].totalRequest+1);
                DiffOf[cid].totalRequest = 0;
                return DiffOf[cid].currentDiff;
            }
        }
    }
    
    function() public payable{}
    
}