# OpenDanmaku: A decentralized danmaku service based on blockchain 


## Abstract
Opendanmaku is a decentralized danmaku service based on Ethereum and ipfs. The user retrieves the specified cid in Ethereum to obtain the hash information of the corresponding danmaku file, and then obtains the corresponding danmaku through ipfs. When the user sends the danmaku, he can write the danmaku to the end of the requested file and send it to ipfs, and then write the hash information to Ethereum.

## Introduction 
Nowadays, people are more and more aware of the copyright protection of multimedia on the internet. It is not a bad thing, but today, As long as the video posted on the video website involves some infringing content, even if it is very rare, the video will be very likely to be blocked or removed from the shelf. At the same time, the other service provided by the video website (such as comments, subtitles, and the main content of this article: danmaku service) will be unavailable.  
To solve this problem is not very hard, Some sites like IDMb provides some services such as ratings and reviews of movies, and they don’t necessarily own the copyright of the original movie. Same as that, we can built a centralized server, indexed by video’s hash, receive danmakus posted by users and response them to anyone requests the same hash. It is easy to implement, but with the following reason, it is still not very good. 
In some contries or regions, when you published some danmakus, your danmaku will face the problem of harsh censorship, and more than that, the copyright of danmakus published by you might not belong to you according to niconico’s Terms of Use[1]. Besides that, centralized service is easy to be attacked, and hard to profit. These have hindered its development. 
The idea of a “decentralized danmaku service” is aimed to solve those problems.  
 
## Decentralized 
In recent decades, Some other decentralized projects (such as bittorrent, bitcoin, etherum and etc.) have achieved good development, sowe we are not need to implement a decentralized framework from scratch. 
In the demo, I chose to use Ethereum and ipfs, two existing and mature projects. 
When you send an Ethereum transaction, you can write some custom data the blockchain. With that, we can write our danmakus to the blockchain. But, write data in Ethereum’s blockchain is a huge expense, in order to avoid that problem, we can write danmakus on ipfs, then write danmakus’ hash on the blockchain. When requesting for the danmakus, client get the danmakus’ hash from blockchain, then request danmaku fron ipfs gateway and get the danmaku; when adding danmaku, client can add the new danmaku to the tail of danmakus requested, then upload to ipfs to get a new hash, then write new hash to the blockchain. With that way, it can decrease lots of costs. 
 
## Dammaku 
### Danmaku storage
According to "activity-danmaku2019" published by bilibili[2], a total of 1,411,973,966 danmakus were generated in 2019. These danmakus occupied about a total of 140gb of storage.
So even total size of danmakus is smaller than total size of blockchain produced per year, it is still bettrt store danmakus in ipfs rather than.

### Tolerance
Observe any video with a lot of danmakus, we will easily find that some video could contains huge amount of danmakus (more than 200,000/20min), but only 1000-8000 danmakus were presented to viewer, it means "tolerance for completeness". And even though we only got a part of the total danmakus, we can still feel that we're watching with others, and we don’t even care if there is a new danmaku that is added simultaneously while watching, it means "tolerance of timeliness".
With these two attributes, we can ensure that even if the danmaku service is on a crowded, high-latency blockchain will not affect the experience.

### Identity
Generally we can use the hash of the danmaku's content, timestamp and sender's uid as a danmaku's identity used for identify and deduplication.

### File
In general, the body of a danmaku should be encapsulated with json because it is easy to use. A danmaku should contains its position(time), position(on screen), sender's uid, timestamp, effect type, content and etc. And it is extensible to cope with other subsequent demands.

### File association
It is common that same video content to have multiple different hashes. Different resolutions, bitrates, subtitles, etc. will cause the hashes to change. For a better experience, we need to correlate the hash values of these files.
In that demo if you want associate two files together, you can use the same way as sending danmaku store a key-value in danmaku's json file. key is new file's hash and value is a function that map the danmaku position in the new file to the original file in order to let is be used normally when the new video is revised (for example, the video is clipped by a small part).

## Built-in token
This project can also have a built-in token, the main purpose is to reward the submission of the danmaku on the chain, as a certain degree of compensation for the cost of the submission of the danmaku. At the same time, for those who have donated to this project, they can also get a certain amount of token rewards.
The number of tokens held by the user can also be used as a basis for calculating the weight of the user's vote when voting, for example, modification of some parameters in the contract, determination of the use of the money donated by the user, and so on.
In the demo, users can freely convert between tokens and Ethereum through collateral and redemption to facilitate the circulation and use of tokens. The exchange rate between Ethereum and tokens is not necessarily the same, and the difference between them can be regarded as a donation to the project.

## Anti-attack
As an open source decentralized danmaku service, it may face this attack from many aspects, for example, it may receive a lot of meaningless spam. The anonymization feature allows spammers to easily inject large amounts of spam into the chain, but this is not uncontrollable.
First, we can set certain restrictions on the submission of danmaku in the contract, for example, limit the frequency of submission of each Ethereum address, and also make certain calculation requirements for the submission of danmaku. Without affecting the normal use of ordinary people, the submission of large amounts of information will consume a lot of time and money, which can increase the cost of spam. Secondly, opendanmaku provides a very large cid space, it is almost impossible to be traversed, the same content can occupy multiple cid at the same time, and a submission can only be submitted to one cid, a wide range of spam submission will consume the amount Huge transaction fee. Lastly, every time the danmaku is submitted on the chain, an event is triggered and stored in the EVM log. Even if abnormal data is requested during use, the previous submission information can be found in the log and used normally.

## Redundant duplication
During the use of opendanmaku, the number of danmaku will continue to increase with the use of the process. Although the previous article has proved that the current danmaku growth rate only accounts for a very small part of the storage space provided by ipfs, but this is not without problems.
One of the problems with danmaku storage is the massive repetition of danmaku. In the process of sending the danmaku, we will first request a file that stores n danmaku, then we add the newly sent danmaku to the end of the file, save the new file and submit it to the ipfs network. However, in this process, the files that previously stored n danmaku will not be destroyed, which will cause the space required to store the danmaku to increase at the rate of o (n ^ 2). For long-term use, this It is unbearable.
At present, it is a relatively negative approach to this problem, that is, no treatment. After the new danmaku file is submitted, the old danmaku file is generally not accessed anymore, and the general ipfs node is likely to clear the files that have not been accessed for a long time to save space. This process can ensure that opendanmaku will not occupy too much ipfs storage.
A better solution is to use the nature of ipfs' own slice. When updating the danmaku list, group all the danmaku in a certain way and then upload it. In this way, the process of newly submitting the danmaku only needs to upload new parts and modify the Merkel tree, to a certain extent, avoid wasting resources.

## Middle server
The process of submitting a danmaku in Ethereum requires a certain handling fee. Although this can effectively avoid the emergence of spam, it is too expensive for most users who only want to send a few danmaku.
We can use a "middle server" approach to further reduce the cost of use. The intermediate server can publish its own IP and port number, and monitor the danmaku requests from others. When the intermediate server receives enough danmaku from other users or continuously monitors the danmaku sent to a cid for a certain time, it can package and upload the received danmaku together to reduce the cost of a single danmaku . Not only that, when other users want to request a danmaku, they can also make a request from the intermediate server, so as to obtain more danmaku that has not been packaged with lower latency.
Sending the danmaku to the intermediate server is not necessarily free. The intermediate server can request other users to provide certain computing power to help the intermediate server mine while sending the danmaku to it. For each user, the danmaku can be sent with less computing power.
One of the benefits of the intermediate server is that it makes it easier for other users to use opendanmaku. When other users want to send or request a danmaku, they do not need to install the ipfs client and Ethereum wallet on their computers in advance, as long as they send the request to the intermediate server through a certain method, the intermediate server can replace This process, thereby reducing the cost of use for ordinary users.

## References
[1] [Niconico Terms of Use] (https://account.nicovideo.jp/rules/account)
[2] [2019bilibili年度弹幕] (https://www.bilibili.com/blackboard/activity-danmaku2019.html)
[3] [ACFUN/BILIBILI 利用磁力链接网络，实现去中心的弹幕视频体验（以及改装成聊天室、论坛、匿名版等等）？] (https://www.v2ex.com/t/170114)
[4] [The idea of a decentralized danmaku (弾幕) and subtitles service] (https://aplacenearby.ggr.fun/danmaku/)