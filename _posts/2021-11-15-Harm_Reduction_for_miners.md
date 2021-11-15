---
title: harm reduction for miners
subtitle: examination of miners as an at-risk population (internal and external factors), ideas for applying harm reduction to reduce potential losses and navigating the opaque waters of Maximal Extracted Value
tags: [ethereum, blockchain, distributed computing, mev, flashbots]
---

<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

# Harm Reduction for Miners

> Harm reduction methodology: An examination of miners as an at-risk population (internal and external factors), ideas for applying harm reduction to reduce potential losses and navigating the opaque waters of Maximal Extracted Value


### Notice

This is written in response to ['A Snake in the Garden'](https://hackmd.io/fvLQzbwVR-qZizmJvSnjOQ#A-Snake-in-the-Garden). This is not meant to be construed as a 'take down piece'/'hit piece', nor should you come away with the impression that one startup/solutions provider is more favoured. This is just adding more context and sources to this topic

#### Disclaimers and Potential Conflicts of Interest

> The Author has no holdings in ArcherDAO/Eden Network. 
> The author has a position in LIDO, which has recently seen an investment by Paradigm.
> The Author holds YFI, (W)ETH, DAI, USDC, FOLD, CRV, and (x)SUSHI. This does not include airdropped tokens.



## What ArcherDAO was and was not

### ArcherDAO

> Since the London fork went live, Archer DAO has pivoted from a DEX offering MEV protection to becoming the Eden Network, a MEV marketplace with a token utilized to secure “slots” at the top of the block & priority transaction features for “stakers”. 

ArcherDAOoriginally was not a DEX offering, at all.

From their original documentation (sic):

> Each supplier that signs up for the Archer network is assigned 3 things:

> An API key used to submit opportunities to the network (unique to each supplier)
> A Bot ID that is used to identify the bot sending each opportunity + distribute rewards to suppliers (each supplier can have multiple)
> A Dispatcher contract that executes transactions sent via API request and, optionally, serves as a liquidity pool the supplier can use to support their strategies
> Suppliers send POST requests to the Archer REST API with the payloads necessary to execute their transactions. See documentation for these requests here.

> Archer finds the most profitable transactions each block and submits them to the network on behalf of the suppliers. If a miner within the Archer network mines this transaction before the opportunity expires and places it in priority position (first tx in block), then the resulting profit will be split between the miner, the supplier, and the network (with splits and other incentives to be determined by Archer DAO).


![](https://d.pr/i/kjN8wr.jpeg)

[Additional sources to the ArcherDAO API documentation](https://docs.google.com/document/d/178mTvHjqIM0sFx_AM3NpnqCG68WNKvtrgKc3iSMAE2g/edit)


### ArcherSwap

From their readme (sic):

> Archerswap is a proof-of concept DEX extension that allows users to execute Uniswap and Sushiswap trades without having to worry about:

> Slippage
> Frontrunning/Sandwich Attacks
> Failed Transaction Cost
> Transaction Cancellation Cost

[source via github.com/archerdao/archerswap](https://web.archive.org/web/20210928011146/https://github.com/archerdao/archerswap)



### Cry Havoc and let slip the Mining Pool Operators

Several individual miners have raised similar concerns, see this popular post on r/EthMining (Important) Gang of Thieves – How Mining Pools Are Stealing 100s of Millions from ETH Miners

If you care to click through this reddit users post history, he is quite obsessed with how certain pools redistribute MEV profits, as he should be.

**How can Eden Network coerce mining pools to distribute profits anymore than Flashbots can do the same to mining pool affiliates?** The answer is they can not directly pay miners themselves, in fact the arrangement has always been to pay the mining pool *operator*. A quarterly transparency report can help ameliorate this issue, along with conducting monthly community discussions with network participants.


In reality this is a simple direct to miner relay feature, for example MEV Alpha Leak’s RPC endpoint. 
This is a considerable oversimplification of how I presume Eden's internal virtualized mempool operates. 
MEV Alpha Leak's RPC endpoint is a proxy service, with some ML adapters bolted on in a completely opaque way. One could also claim that flashbots is merely 'a miner relay service' with the added benefit of load balancer and basic DDoS protections.


### Help me, help you.

> source https://hackmd.io/fvLQzbwVR-qZizmJvSnjOQ#Protect

The only novel thing Eden allows is for protocols to sponsor users. While this is innovative, it requires no token and is yet another example of Eden attempting to wall off features that should be permission-less.

Flashbots is not permission-less. This is a strawman argument.

In fact Flashbots has already pre-envisioned a world in which your reputation is tokenized, 

> The biggest issue the relay is facing right now are intermittent dos attempts which take up all the relay capacity - regular usage has not been an issue. This means paying searchers won't crowd out non-paying users.
> 
> I think the solution will end up being to provide multiple paths to inclusion for searchers. Just like a good mmorpg, players may want to xp farm their way to high reputation, or they may want to take the easy path and pay to win ;)
> 
> Here is what that could look like:
> 
> * users default to being in the low reputation queue and risk getting crowded out
> * low reputation searcher can play the reputation game and eventually move to high reputation queue if they have good performance over time
> * low reputation searcher can do a donation or burn to boost their reputation, but risk dropping back down to low reputation if don't perform well
> * any searcher can pay for guaranteed capacity in the high reputation queue

https://github.com/flashbots/pm/discussions/79#discussioncomment-938640


<blockquote class="twitter-tweet"><p>Contrary to Multicoin&#39;s claims, minimizing MEV is core to Flashbots&#39; mission &amp; products.<br />That shows from our funding of fairness and ethics research, work on MEV aware dApps, &amp; 100s of users that have used Flashbots to skip the mempool &amp; protect themselves from frontrunning.</p>&mdash; Robert Miller (@bertcmiller) <a href="https://twitter.com/bertcmiller/status/1435686480270217226?ref_src=twsrc%5Etfw">September 8, 2021</a></blockquote> 

- Except when it comes to protecting participating Miners in Flashbots, for example a few miners have been given the privlage of having their Identity redacted. 


Here is the complete, un-redacted Flashbots list of miners (A-Z):

2miners
4hash
666pool
antpool
babelpool
beepool
binancepool
btc-com
crazypool
ethermine
ezilpool
f2pool
firepool
flexpool
hiveon
huobipool
k1-pool
luxor
minerall
miningdao
miningexpress
miningpoolhub
nanopool
pandapool
poolin
solopool
sparkpool
spiderpool
uupool
viabtc
xnpool


<blockquote class="twitter-tweet"><p>Of course, it’s not in Eden’s interests to provide more transparency. <br />Eden&#39;s success relies on their token pumping. That&#39;s the only way miners might stomach the 40% tax (only 60% of inflation goes to miners) that Eden and their investors want to levy on MEV.</p>&mdash; Robert Miller (@bertcmiller) <a href="https://twitter.com/bertcmiller/status/1435686490823135235?ref_src=twsrc%5Etfw">September 8, 2021</a></blockquote>

<!-- 
Another claim of transparency, yet took more than 6 months to disclose publicly funding by Paradigm, their 'current capital partners'.
[source: https://github.com/flashbots/pm/commit/1f1c08b7a73860a3f2da7ffdab5d2cbb9fedbe40](https://github.com/flashbots/pm/commit/1f1c08b7a73860a3f2da7ffdab5d2cbb9fedbe40)

This is not to disparage Paradigm or the people who work within its confines. They employ (and attract) some of the greatest talent in this Industry, to me this seems more of an ad hominem attack that leaves more questions than answers. How is it not in Edens interest to provide transparency? Would it not further legitimize their choice of pivot and focus vis a vie ArcherDAO? The Inflation dig towards the end of Mr. Miller's comment would be well to be reminded that until very recently, Ethereum's monetary policy was also a purely inflationary scheme. However without knowing more about Eden's particular agreements with its investors, a through and accurate analysis will have to wait until then.

-->

#### Double Dip

Also, Flashbots members evidently host their own private relay endpoints, who knew? [https://securitytrails.com/domain/relay.epheph.com/history/a](https://securitytrails.com/domain/relay.epheph.com/history/a)



## MEV Data-ish

<!-- Data issues -->

"Most deadly errors arise from obsolete assumptions."

-Frank Herbert





## Remarks

> **Let us not loose sight on the true enemey**
> 
![](https://d.pr/i/jGTgQV.jpeg)




## Sources and Links

- [A Snake in the Garden](https://hackmd.io/fvLQzbwVR-qZizmJvSnjOQ)

- [Flashbots Project Management](https://github.com/flashbots/pm/commit/1f1c08b7a73860a3f2da7ffdab5d2cbb9fedbe40)

- https://twitter.com/bertcmiller/status/1435686480270217226

- [Additional sources to the ArcherDAO API documentation](https://docs.google.com/document/d/178mTvHjqIM0sFx_AM3NpnqCG68WNKvtrgKc3iSMAE2g/edit)


### Archival Links

- https://web.archive.org/web/20210922071908/https://github.com/flashbots/pm/discussions/79
- https://web.archive.org/web/20210922071946/https://twitter.com/bertcmiller/status/1435686480270217226
- https://web.archive.org/web/20210928011146/https://github.com/archerdao/archerswap


#### License and Copyleft

We make no claim on any copyrighted material, all rights reserved of their respective owners.

CC-4.0-SA