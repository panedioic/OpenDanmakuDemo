README.md

# 简介
OpenDanmaku 是一个开源的，去中心化的弹幕服务协议。一言以蔽之，OpenDanmaku 的存在就是为了让你在看你下载的番时有弹幕。
（目前这个项目只是可以上传/下载弹幕，弹幕效果还需要使用例如 弹弹play 之类的弹幕播放器）

# 使用
## 一、使用IPFS
（IPFS 的安装不是必须的，你可以通过[IPFS公共网关列表](https://ipfs.github.io/public-gateway-checker/)找到公共网关来代替安装本地IPFS节点进行工作）

### 1.1 下载节点软件
到官网下载windows版的ipfs节点软件：https://dist.ipfs.io/

### 1.2 解压节点软件
下载后解压到指定目录，例如d:\go-ipfs，开一个控制台窗口，测试：
```
D:\go-ipfs > ipfs version
Ipfs version 0.4.14
```
可以将该目录加入环境变量PATH。

### 1.3 初始化本地仓库
和git类似，ipfs节点也需要先初始化一个本地仓库。执行init子命令来初始化本地仓库：
```
D:\go-ipfs> ipfs init
Initializing IPFS node at C:\Users\hubwiz\.ipfs
generating 2048-bit RSA keypair...done
peer identity: QmQaTgU1TLNHPBEvLGgWK1G9FgVByyUZNVhDs789uWPtku
to get started, enter:

     ipfs cat /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme
```
默认情况下，ipfs将在当前用户主目录（例如：对于hubwiz用户，其主目录就是C:\Users\hubwiz）下建立.ipfs子目录，作为本地仓库的根目录。

如果你的C盘空间不够大，或者你就是希望使用其他目录作为本地仓库根目录，可以设置IPFS_PATH环境变量，使其指向目标路径，例如D:\my_ipfs_root
a
## 二、使用Metaemask钱包
如果你不想使用Metarmask钱包，你也可以使用其他能正常使用DAPP的钱包。
在测试链中使用并不需要你花费金钱购买以太币，这是完全免费的。

你可以在chrome商店直接搜索 Metamask 下载该钱包。

安装完钱包后，根据插件的提示记下助记词并初始化钱包，之后点击上方的“以太坊主网络，切换为 Ropsten 测试网络，之后点击： "存入 - 测试水管 - 获取 Ether - request 1 ether from faucet" 获取你的测试用以太币。

## 三、使用
之后就可以下载 `index.html`, `index.js`, `abi.json`开始使用了。
注意本地文件是不支持直接使用Metamask钱包的，你可以使用`python -m http.server`之后使用。
你还可以直接访问 https://gateway.ipfs.io/ipfs/QmU7iiCM8ZedgYc6pqpXEbC4GsEPvfJhvV5LJ7Bg67jKNA/ 我已经将其上传至了ipfs。

# 项目说明
额，不知道还有什么要说明的了，有的话之后再补吧
至于 OpenDanmaku.md 这个东西，完全就是我突然犯中二病搞出来的东西，忽略掉它就好了。