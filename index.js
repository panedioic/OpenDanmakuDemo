var global_config = {
    use_middle_server: false,

    use_injected_web_provider: true,
    web_provider: 'http://127.0.0.1:7545',

    use_local_ipfs_upload: true,
    use_local_ipfs_gateway: false,

    contract_address: '0xf5ce613a0a421F8810520130fA2d8Aa7abFEA5E1',

    public_gateway: 'https://ipfs.globalupload.io/'

}

request = new XMLHttpRequest();
request.onreadystatechange = function () {
    if (request.readyState === 4 && request.status === 200) {
        global_config.contract_abi_str = request.responseText;
    }
}

request.open('GET', './abi.json', false);
request.send();
console.log(global_config.contract_abi_str.length);

var test_fileaddr = 'QmSgS9Su46KVfAZvMBUuyj1WLnwMM1rdgX3LzZeBjAijkb';
var danmaku_file;
var global_cid = 0;
var add_num = 0;

var ipfs;

contract_abi = JSON.parse(global_config.contract_abi_str);

if (global_config.use_middle_server) {
    // 然而我并不会...
} else {
    if (global_config.use_injected_web_provider) {
        //web3 = new Web3(web3.currentProvider);
        if (typeof web3 !== 'undefined') { 
            ethereum.enable();
            console.debug(web3.currentProvider);
            web3 = new Web3(web3.currentProvider);
        } else {
            alert("No currentProvider for web3");
        }
        console.warn("Meata");
    } else { 
        web3Provider = new Web3.providers.HttpProvider(global_config.web_provider);
        web3 = new Web3(web3Provider); 
    }

    if(global_config.use_local_ipfs_gateway || global_config.use_local_ipfs_upload){
        ipfs = window.IpfsApi({
            host: '127.0.0.1',
            port: 5001,
            protocal: 'http'
        });
        //console.log(ipfs);
    } else {
        //然而我并没有学会公共网关的用法.....
    }
}

ODDContract = web3.eth.contract(contract_abi);
contractInstance = ODDContract.at(global_config.contract_address);

function decode_addr(hexarr, len){
    res = "";
    for(i = 0;i < len; ++i){
        res += String.fromCharCode(parseInt(hexarr[2*i+2]+hexarr[2*i+3],16));
    }
    return res;
}

function get_nonce_sto(pf, diff, maxtry){
    for(i=0;i<maxtry;++i){
        nonce = Math.floor(Math.random()*2**2); 
        // 我不会写这个函数，等着大佬补充吧，反正测试的时候难度都是0.
        return 0;
    }
    return NaN;
}

function get_nonce_reg(cid, diff, maxtry){
    for(i=0;i<maxtry;++i){
        nonce = Math.floor(Math.random()*2**2); 
        // 同上，这个就先这样了....
        return 0;
    }
    return NaN;
}

function get_difficult(value){
    // 同，之后再补吧，反正现在难度都还是0
    return (2<<256)-1;
}




function get_danmaku(){
    if(document.getElementById('getter-get').value === ""){
        console.error('Please input cid!');
        return;
    }
    if(document.getElementById('getter-get').value.substr(0,2) !== "0x"){
        console.error('Wrong cid!');
        return;
    }
    global_cid = document.getElementById('getter-get').value;
    contractInstance.getDanmakuFile.call(document.getElementById('getter-get').value, function(err, res){
        if(res[0].c[0] == 0){
            danmaku_file = {
                protocal: "OpenDanmakuDemo",
                version: 0.1,
                cid: document.getElementById('getter-get').value,
                duration: null,
                references: [],
                danmakus: []
            }
            console.info('No danmaku found. Generated danmaku onject automaticlly.');
        } else {
            addr = decode_addr(res[2], res[0].c[0]);
            console.log(res);

            request = new XMLHttpRequest();
            request.onreadystatechange = function () {
                if (request.readyState === 4 && request.status === 200) {
                    receiveData = JSON.parse(request.responseText);
                    console.log('Received '+receiveData.danmakus.length+' danmakus.')
                    console.log(receiveData);
                    danmaku_file=receiveData;
                }
            }

            request.open('GET', global_config.public_gateway+addr);
            request.send();
        }
    })
}

function report_danmaku(){
    report_cid = document.getElementById('getter-rep-cid').value;
    report_hash = document.getElementById('getter-rep-hash').value;
    if(report_cid === ""){
        console.error('Empty cid!');
        return;
    }
    if(report_hash === ""){
        console.error('Empty hash!');
        return;
    }
    
    contractInstance.userReport(report_cid, report_hash, {from: web3.eth.accounts[0], gasLimit: 6000000}, function(err, res){
        if(err){
            console.error(err);
        }
        console.log("Report success!");
    });
}

function add_danmaku(){
    dm = document.getElementById('getter-send').value.split(",");
    document.getElementById('getter-send').value="";
    if(dm.length < 2){
        console.error('Wrong argument!');
        return;
    }
    var date = new Date();
    dmdata = [];
    dmdata.push(dm[1]);
    dmdata.push(dm.length > 4 ? dm[4] : "1");
    dmdata.push(dm.length > 2 ? dm[2] : "25");
    dmdata.push(dm.length > 4 ? dm[4] : "1");
    dmdata.push(dm.length > 3 ? dm[3] : "16777215");
    dmdata.push(date.getTime().toString());
    dmdata.push(web3.eth.accounts[0]);
    dmdata.push(dm[0]);
    console.log(dmdata.toString());
    add_num += 1;

    if(danmaku_file === undefined){
        console.error('Empty cid!');
        return;
    }
    danmaku_file.danmakus.push(dmdata);
    document.getElementById('temp-change').innerText = '['+add_num+'] ['+dmdata.toString()+']\n'+document.getElementById('temp-change').innerText;
}

var tmpres;
function commit_danmaku(){
    if(add_num === 0){
        console.error('No change!');
        return;
    }
    if(danmaku_file === undefined){
        console.error('Empty cid!');
        return;
    }
    jsonstr = JSON.stringify(danmaku_file);
    buf = buffer.Buffer(jsonstr);
    
    var result;
    if(global_config.use_local_ipfs_upload){
        ipfs.files.add(buf, (err, res) => { // Upload buffer to IPFS
            if(err) {
            console.error(err);
            return;
            }
            let url = `http://127.0.0.1:8080/ipfs/${res[0].hash}`;
            console.log(`Url --> ${url}`);
            result = res[0].hash;

            contractInstance.getDanmakuFile.call(cid, function(err, res){
                parentHash = res[3];
                nonce = get_nonce_sto(parentHash, 1<<255, 100);
                try {
                    contractInstance.storeDanmakuFile(cid, result.length, add_num, parentHash, result, nonce, {from: web3.eth.accounts[0], gasLimit: 6000000}, function(err, res) {
                                    
                        console.log(danmaku_file);
        
                        add_num=0;
                        document.getElementById('temp-change').innerText = 'Commit success on '+res+'!';
        
                        if(err){
                            console.error(err);
                        }
                    });
                } catch (err) {
                    console.error(err);
                }
            });
        })
    } else {
        console.warn('No local ipfs, failed to upload.');
        result = test_fileaddr;
    }
    cid = global_cid;
}

function user_register(){
    if(document.getElementById('getter-reg').value === ""){
        console.error('Please input cid!');
        return;
    }
    if(document.getElementById('getter-reg').value.substr(0,2) !== "0x"){
        console.error('Wrong cid!');
        return;
    }
    global_cid = document.getElementById('getter-reg').value;
    diff = get_difficult('reg');
    nonce = get_nonce_reg(global_cid, diff, 100);
    contractInstance.userRegister(global_cid, nonce, {from: web3.eth.accounts[0]}, function(err, res) {
        if(err){
            console.error(err);
        }
        console.log('Success at '+res+' !');
    });
}

function token_balanceof(){
    token_value = document.getElementById('getter-token-bal').value;
    if(token_value=""){
        console.error("Please input address!");
    }
    contractInstance.balanceOf.call(token_value, function(err, res){
        console.log(res);
    });
}

function token_transfer(){
    token_address = document.getElementById('getter-token-tra-addr').value;
    token_value = document.getElementById('getter-token-tra-val').value;
    if(token_address=""){
        console.error("Please input address!");
    }
    if(token_value=""){
        console.error("Please input value!");
    }
    contractInstance.transfer(token_address, token_value, {from: web3.eth.accounts[0]}, function(err, res) {
        if(err){
            console.error(err);
        }
        console.log('Success at '+res+' !');
    });
}

function token_deposit(){
    token_value = document.getElementById('getter-token-dep').value;
    contractInstance.deposit({from: web3.eth.accounts[0], value: parseInt(token_value)}, function(err, res) {
        if(err){
            console.error(err);
        }
        console.log('Success at '+res+' !');
    });
}

function token_withdraw(){
    token_value = document.getElementById('getter-token-wit').value;
    if(token_value=""){
        console.error("Please input value!");
    }
    contractInstance.withdraw(token_value, {from: web3.eth.accounts[0], value: parseInt(token_value)}, function(err, res) {
        if(err){
            console.error(err);
        }
        console.log('Success at '+res+' !');
    });
}