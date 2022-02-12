---
title: Liquidity Adjusted Arrival Price
subtitle: Benchmarking Trade Execution and Routing
tags: [ethereum, blockchain, distributed computing, routing, amm, trading]
---

#### The execution quality metric every crypto trader should follow

**It's hard to tell when you're doing execution well; it's easy to tell when
you're doing it poorly.**

This is the first part of a series about execution quality benchmarks and
statistics. Today, we'll discuss perhaps the most important of execution quality
benchmarks: we call it the _liquidity-adjusted arrival price_.

#### What is execution quality?

Before we discuss the details, let's recap the basics of execution quality. In
general, we assume we have a trader looking to buy or sell some quantity at the
best available price. By _execution quality_, we mean the trader's ability to
obtain a good price.

So what's a _good_ price? That's the critical question, and it's the one we'll
address today. Traders interested in optimizing execution quality are usually
doing fairly large volumes; for this reason, _market impact_ — or the process of
adversely affecting available market prices due to the force of one's own trade
— is often the primary concern. But the things we'll discuss today don't only
impact whales: indeed, this affect all traders. Even a 50,000 USD trade can
create waves in crypto, depending on the circumstances.

Of course, it's a murky question what a "good price" is. While it's crystal
clear what the trader's realized price was, it's always difficult to say what a
"good" price might have been. It's impossible, for example, to predict how the
market would have behaved in the trader's absence. (This is sometimes known as
the _Fundamental Problem of Experiments_.) It's difficult to estimate how
traders may have reacted to other strategies, particularly ones that may have
substantively altered the public order book.

#### Liquidity-Adjusted Arrival Price - LAAP

So let's come up with a "good price." Imagine we had a perfect trader —
light-speed hands, access to all markets, the ability to do 10 things at once,
and, most of all, faster Internet speeds than all other market participants.
This trader would go through public order books and hit (lift) every bid (offer)
they want until they reach the full amount requested by the user. (This process,
known as "sweeping" the order book, almost never turns out the way it would for
this theoretical trader, but let's go with it.)

Naturally, any sizable order will create some amount of market impact: by
chewing through the available orders, and with no opportunity for liquidity to
replenish itself, the price obtained would be potentially quite different from
the top-of-book price before we started.

This price — the one we'd obtain by sweeping the order book at the time the
trade is submitted — is the _liquidity-adjusted arrival price_. Quite simply, it
tells you what you could've gotten with a really simple algorithm, a really
attentive trader, or a really lucky market order.

#### Interpretation

In real life, sweeping the book won't actually get you this perfect price.
You'll get something close but slightly different, simply due to changes in the
order book before you have a chance to act. But, it shouldn't be hard to get
this price (or a price close to it) with a fairly straightforward execution
technique, like an inter-market sweep.

For large volume trades, if your execution price is worse than the LAAP, it
might be worth considering tightening up the timeframes given to algorithms, or
adopting a more passive trading posture. And, certainly, OTC quotes should never
be accepted outside the bounds given by this number — this would be a literal
arbitrage for the OTC desk.

#### Adjustments

We left out some critical details that are important when doing this analysis in
practice.

First, we need to adjust for fees. The LAAP would incur taker-side fees, so
these need to be factored into the price. Most execution techniques will attempt
to stay passive in order to avoid fees, so it's important to create an
apples-to-apples comparison by adjusting for fees appropriately.

Second, and far more complicated, is the question of risk-adjustment. There may
be more risk in one execution technique over the other. If this is the case, a
punitive factor can be applied to capture the value of risk mitigation. For
example, the buy-immediately strategy is known to be the riskiest due to the
possibility that a short-term liquidity shortfall create outsize price impact;
for this reason, the LAAP is often adjusted by some value linear in the product
of the asset's volatility and the square root of time.

#### Conclusion

If there's one execution quality metric you need to know, it's this one. If the
simplest approach possible would perform better than what you're doing today,
it's worth seriously reconsidering the current approach.

### Citations

- Jason Victor, LAAP Article, Routefire
