---
created: 2022-11-21T12:45:43 (UTC -07:00)
source: https://bford.info/2019/09/23/rational/
author: Bryan Ford
---

# Rationality is Self-Defeating in Permissionless Systems

> ## Excerpt
>
> Many blockchain and cryptocurrency fans seem to prefer building and analyzing
> decentralized systems in a rational or “greedy behavior” failure model, rather
> than a Byzantine or “arbitrary behavior” failure model. Many of the same
> blockchain and cryptocurrency fans also like open, permissionless systems like
> Bitcoin and Ethereum, which anyone can join and participate in using weak
> identities such as anonymous cryptography key pairs.
> _by [Bryan Ford](https://bford.info/) and
> [Rainer Böhme](https://informationsecurity.uibk.ac.at/people/rainer-boehme/) —
> [PDF preprint](https://arxiv.org/pdf/1910.08820.pdf) version available_

Many blockchain and cryptocurrency fans seem to prefer building and analyzing
decentralized systems in a rational or “greedy behavior” failure model, rather
than a Byzantine or “arbitrary behavior” failure model. Many of the same
blockchain and cryptocurrency fans also like open, permissionless systems like
Bitcoin and Ethereum, which anyone can join and participate in using weak
identities such as anonymous cryptography key pairs.

What most of these heavily-overlapping sets of fans do not seem to realize,
however, is that rationality assumptions are self-defeating in open
permissionless systems with weak identities. A fairly simple metacircular
argument – a kind of
“[Gödel's incompleteness theorem](https://en.wikipedia.org/wiki/G%C3%B6del%27s_incompleteness_theorems)
for rationality” – shows that for any system _S_ that makes _any_ behavioral
assumption, including but not limited to a rationality assumption, a rational
attacker both exists and _has an incentive_ to defeat that behavioral
assumption, thereby violating that assumption and exhibiting Byzantine behavior
from the perspective of the system.

As a quick summary of the argument we will expand below, suppose a
permissionless system like Bitcoin is secure against rational attacks, but has
some weakness against irrational Byzantine attacks in which the attacker would
lose money. Because the system is open, permissionless, and exists within a
larger ecosystem, a rational attacker can find ways to “bet against” Bitcoin's
security in _other_ financially-connected systems (e.g., Ethereum), making a
profit _outside of_ Bitcoin on this attack against Bitcoin. An attack that
appears irrational in the context of Bitcoin may be perfectly rational in the
context of the larger ecosystem.

For this reason, an open permissionless system designed to be secure only
against rational adversaries is actually just _insecure_, unless it remains
secure even when the “rational” participants become fully Byzantine. Given this,
one might as well have designed the permissionless system in a Byzantine model
in the first place. The rationality assumption offers no actual benefit, but
merely can make an insecure system appear secure under flawed analysis.

This blog post is based partly on ideas in
[Rainer Böhme's talk](https://web.archive.org/web/20191124192837/https://bdlt.school/files/slides/talk-rainer-b%C3%B6hme-a-primer-on-economics-for-cryptocurrencies.pdf)
at the recent
[BDLT Summer School in Vienna](https://web.archive.org/web/20210416231544/https://bdlt.school/).
While formalizing the argument would require some effort, we thought it would be
worth at least sketching the argument intuitively for the public record.

## Threat Modeling: Honest, Byzantine, and Rational Participants

In designing or analyzing the security of any decentralized system, we must
define the system's _threat model_, and in particular our assumptions about the
behaviors of the participants in the system. An _honest_, _correct_, or
_altruistic_ participant is one that we assume to follow the system's protocol
rules as specified, hence representing a “well-behaved” participant exhibiting
no adversarial behavior.

A _Byzantine_ participant, named after the
[Byzantine Generals Problem](http://theory.stanford.edu/~trevisan/cs174/byzantine.pdf),
is one we make _no_ assumptions about. A Byzantine participant can behave in
_arbitrary_ fashion, without restriction, and hence by definition represents the
strongest possible adversary.

We would like to build systems that could withstand _all_ participants being
Byzantine, but this appears fundamentally impossible. We therefore in practice
have to make threshold security assumptions, such as that over two-thirds of the
participants in classic Byzantine consensus protocols are honest, or that the
participants controlling over half the hashpower in Bitcoin are well-behaved.

Even with threshold assumptions, however, building systems that resist Byzantine
behavior is extremely difficult, and the resulting systems are often much more
complex and inefficient than systems tolerating weaker adversaries. We may
therefore be tempted to improve a design's simplicity or efficiency by making
stronger assumptions about the behavior of adversarial participants, effectively
weakening the assumed adversary.

![Types of adversaries](https://bford.info/2019/09/23/rational/adversaries.svg)

One such popular assumption, especially in economic circles, is _rationality_.
In essence, we assume that rational participants may deviate from the rules in
arbitrary ways but _only when doing so is in their economic self-interest_,
improving their expected rewards – usually but not always financial – in
comparison with following the rules honestly.

By assuming that adversarial participants are rational rather than Byzantine, we
need not secure the system against _all_ possible participant behaviors, such as
against participants who pay money with no reward merely to sow chaos and
destruction. Instead, we merely need to prove that the system is _incentive
compatible_, for example by showing that its rules represent a Nash equilibrium,
in which deviations from the equilibrium will not give participants a greater
financial reward.

Besides simplicity and efficiency, another appeal of rationality assumptions is
the promise of _strengthening_ the system's security by lowering the threshold
of participants we assume to be fully honest. To circumvent the classical
Byzantine consensus requirement that fewer than one third of participants may be
faulty, for example, we might hope to tolerate closer to 50%, or even 100%, of
participants being “adversarial” if we assume they are rational and not
Byzantine. Work on
[the BAR model (Byzantine-Altruistic-Rational)](http://www.cs.utexas.edu/~lorenzo/papers/sosp05.pdf)
and
[_(k,t)_\-robustness](http://www.cs.utexas.edu/~lorenzo/papers/Abraham11Distributed.pdf)
exemplifies this goal, which sometimes appears achievable in closed systems with
strong identities. But a direct implication of our metacircular argument is that
an _open_ system cannot generally be secure if all participants are either
Byzantine or rational.

## Assumptions Underlying the Argument

The metacircular argument makes three main assumptions.

First, the system _S_ under consideration is open and permissionless, allowing
anyone to join and participate in the system using only weak, anonymous
identities such as bare cryptographic key pairs. Identities in _S_ need not even
be costless provided their price is modest: the argument still works even if _S_
imposes membership fees or requires new wallet keys to be “mined”, for example.
Proof-of-Work cryptocurrencies such as Bitcoin and Ethereum, Proof-of-Stake
systems such as Algorand and Ouroboros, and most other permissionless systems
seem to satisfy this openness property. Because participation is open to anyone
globally and can be anonymous, we cannot reasonably expect police or governments
to protect _S_ from attack: even if they wanted to and considered it their job,
they would not be able to find or discipline a smart rational attacker who might
be attacking from anywhere around the globe, especially from a country with weak
international agreements and extradition rules. Thus, _S_ must “stand on its
own”, by successfully either withstanding or disincentivizing attacks coming
from anywhere. (And it will turn out that merely disincentivizing such attacks
is impossible.)

Second, the system _S_ does not control a majority of total economic power or
value in the world: i.e., it is not totally economically dominant from a global
perspective. Instead, there may be (and probably are) actors outside of _S_ who,
if rationally incentivized to do so, can at least temporarily muster an amount
of economic power outside of _S_ comparable to or greater than the economic
value within or controlled by _S_. In other words, we assume that _S_ is not the
“biggest fish in the ocean.” Given that there can be at most one globally
dominant economic system at a time, it seems neither useful nor advisable to
design systems that are secure only when they are the biggest fish in the ocean,
because almost always they are not.

Third, the system _S_ actually _leverages_ in some fashion the behavioral
assumption(s) it makes on participants, such as a rationality assumption. That
is, we assume there exist one or more (arbitrary) behavioral strategies that _S_
assumes some participants _will not_ follow, such as economically-losing
behaviors in the case of rationality. Further, we assume there exists such an
assumption-violating strategy that will cause _S_ to malfunction or otherwise
deviate observably from its correct operation. In fact, we need not assume that
this deviant behavior will _always_ succeed in breaking _S_, but only that it
will non-negligibly _raise the probability_ of _S_ failing. If this were not the
case, and _S_ in fact operates correctly, securely, and indistinguishably from
its ideal even if participants do violate their behavioral assumptions, then _S_
is actually Byzantine secure after all. In that case, _S_ is not actually
benefiting from its assumptions about participant behavior, which are redundant
and thus may be simply discarded.

## The Metacircular Argument: Rational Attacks on Rationality

Suppose permissionless system _S_ is launched, and operates smoothly for some
time, with all participants conforming to _S_'s assumptions about them. Because
_S_ is permissionless (assumption 1) and exists in a larger open world
(assumption 2), new rational participants may arrive at any time, attracted by
_S_'s success and presumably growing economic value provided there is an
opportunity to profit from doing so.

Consider a particular newly-arriving participant _P_. _P_ could of course play
by the rules _S_ assumes of _P_, in which case the greatest immediate economic
benefit _P_ could derive from participating in _S_ is some fraction of the total
economic value currently embodied in _S_ (e.g., its market cap). For most
realistic permissionless systems embodying strong founders' or early-adopters'
rewards, if _P_ is not one of the original founders of _S_ but arrives
substantially after launch, then _P_'s near-term payoff prospectives from
joining _S_ is likely bounded to a fairly _small_ fraction of _S_'s total value.
But what if there were another strategy _P_ could take, for perfectly _rational_
and economically-motivated reasons, by which _P_ could in relatively short order
acquire a _large_ fraction of _S_'s total value?

![Open world with S and S'](https://bford.info/2019/09/23/rational/open-world.svg)

Because _S_ is permissionless and operating in a larger open world, _P_ is not
confined to operating exclusively within the boundaries of _S_. _P_ can also
make use of facilities external to _S_. By assumption 2, _P_ may in particular
have access to, or be able to borrow temporarily, financial resources comparable
to or larger than the total value of _S_.

Suppose the facilities external to _S_ include another Ethereum-like
cryptocurrency _S'_, which includes a smart contract facility with which
decentralized exchanges, futures markets, and the like may be implemented. (This
is not really a separate assumption because even if _S'_ did not already exist,
_P_ could create and launch it, given sufficient economic resources under
assumption 2.) Further, suppose that someone (perhaps _P_) has created on
external system _S'_ a decentralized exchange, futures market, or any other
mechanism by which tokens representing shares of the value of _S_ may be traded
or speculated upon in the context of _S'_: e.g., a series of tradeable Ethereum
tokens pegged to _S_'s cryptocurrency or stake units.

Now suppose participant _P_ finds some behavioral strategy that system _S_
depends on participants _not_ exhibiting, and that will observably break _S_ –
or even that just _might_ break _S_ with significant non-negligible probability.
Assumption 3 above guarantees the existence of such a behavioral strategy,
unless _S_'s rationality assumptions were in fact redundant and worthless. _P_
must merely be clever enough to find and implement such a strategy. It is
possible this strategy might first require _P_ to pretend to be one or more
well-behaved participants of _S_ for a while, to build up the necessary
reputation or otherwise get correctly positioned in _S_'s state space; a bit of
patience and persistence on _P_'s part will satisfy this requirement. _P_ may
also have to “buy into” _S_ enough to surmount any entry costs or stake
thresholds _S_ might impose; the external funds _P_ can invoke or borrow by
assumption 2 can satisfy this requirement, and are bounded by the total value of
_S_. In general, _S_'s openness by assumption 1 and the existence of a
correctness-violating strategy by assumption 3 ensures that there exists some
course of action and supply of external resources by which _P_ can position
itself to violate _S_'s behavioral assumption.

In addition to infiltrating and positioning itself within _S_, _P_ also invokes
or borrows enough external funds and uses them to short-sell (bet against)
shares of _S_'s value massively in the context of the external system _S'_,
which (unlike _S_) _P_ trusts will remain operational and hold its value
independently of _S_. Provided _P_ reaches this short-selling position gradually
and carefully enough to avoid revealing its strategy early, the funds _P_ must
invoke or borrow for this purpose must be bounded by some fraction of the total
economic value of _S_. And provided there are at least some participants and/or
observers of _S_ who believe that _S_ is secure and will remain operating
correctly, and are willing to bet to that effect on _S'_, _P_ will eventually be
able to build its short position.

Finally, once _P_ is positioned correctly within both _S_ and _S'_, _P_ then
launches its assumption-violating behavior in _S_ that will observably cause _S_
to fail as per assumption 2. This might manifest as a denial-of-service attack,
a correctness attack, or in any other fashion. The only requirement is that
_P_'s behavior creates an _observable_ failure, which a nontrivial number of the
existing participants in _S_ believed would not happen because they believed in
_S_ and its threat model. The fact that _S_ is now observed to be broken, and
its basic design assumptions manifestly violated, causes the shares of _S_'s
value to drop precipitously on external market _S'_, on which _P_ takes a
handsome profit. Perhaps _S_ recovers and continues, or perhaps it fails
entirely – but either way, _P_ has essentially transferred a significant
fraction of system _S_'s economic value from system _S_ itself to _P_'s own
short-sold position on external market _S'_. And to do so, _P_ needed only to
find a way – any way – to _surprise_ all those who believed _S_ was secure and
that its threat model accurately modeled _S_'s real-world participants.

Even if _P_'s assumption-violating behavioral strategy does not break _S_ with
perfect reliability, but only with some probability, _P_ can still create an
_expectation_ of positive profit from its attack by hedging its bets
appropriately on _S'_. _P_ does not need a perfect attack, but merely needs to
possess the _correct_ knowledge that _S_'s failure probability is much higher
than the other participants in _S_ believe it to be – because only _P_ knows
that (and precisely when) it will violate _S_'s design assumptions to create
that higher failure probability. Furthermore, even if _P_'s attack fails, and
the vulnerability it exploits is quickly detected and patched, _P_ may still
profit marginally from the market's adjustment to a realization that _S_'s
failure probability was (even temporarily) higher than most of _S_'s
participants thought it was.

Within the context of system _S_, _P_'s behavior manifests as Byzantine
behavior, specifically violating the assumptions _S_'s designers thought
participants would not exhibit and thus excluded from _S_'s threat model.
Considered in the larger context of the external world in which _S_ is embedded,
however, including the external trading system _S'_, _P_'s behavior is perfectly
rational and economically-motivated. Thus, the very rationality of _P_ in the
larger open world is precisely what motivates _P_ to break, and profit from,
_S_'s ill-considered assumption that its participants would behave rationally.

## Implications for Practical Systems

This type of financial attack is by no means entirely theoretical or limited to
fully-digital systems such as cryptocurrencies. In our scenario, _P_ is
essentially playing a game closely-analogous to the investors in
[credit default swaps](https://en.wikipedia.org/wiki/Credit_default_swap) who
both contributed to, and profited handsomely from, the
[2007-2008 financial crisis](https://en.wikipedia.org/wiki/Financial_crisis_of_2007%E2%80%932008),
as covered more recently in the film
[The Big Short](<https://en.wikipedia.org/wiki/The_Big_Short_(film)>).

In the cryptocurrency space, some real-world attacks we are seeing – such as
increasingly-common
[51% attacks](https://cryptoslate.com/prolific-51-attacks-crypto-verge-ethereum-classic-bitcoin-gold-feathercoin-vertcoin/)
– might be viewed as special cases of this metacircular attack on rationality.
It is often claimed that large proof-of-work miners (or proof-of-stake holders)
will not attempt 51% attacks because doing so would undermine the value of the
cryptocurrency in which they by definition hold a large stake, and hence would
be “irrational”. But this argument falls apart if the attack allows the large
stakeholder to reap rewards outside the attacked system, e.g., by defrauding
exchanges or selling _S_ short in other systems.

Externally-motivated attacks on cryptocurrencies have been predicted before in
the form of
[virtual protest or "Occupy Bitcoin" attacks](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2041492),
[Goldfinger attacks](https://www.econinfosec.org/archive/weis2013/papers/KrollDaveyFeltenWEIS2013.pdf),
[puzzle transaction attacks](https://www.comp.nus.edu.sg/~prateeks/papers/38Attack.pdf),
[merged mining attacks](https://www.sba-research.org/wp-content/uploads/publications/201709%20-%20AJudmayer%20-%20CBT_Merged_Mining_camera_ready_final.pdf),
[hostile blockchain takeovers](https://fc18.ifca.ai/bitcoin/papers/bitcoin18-final17.pdf),
and out-of-band variants of
[pay-to-win attacks](https://eprint.iacr.org/2019/775.pdf). All these attacks
are specific instances of our argument. They have been presented in the
literature as open yet solvable challenges. We are not aware, however, of any
prior attempt to summarize the lessons learned and formulate a general
impossibility statement.

For most practical systems, we do not even know if they are incentive compatible
in the absence of an external system _S'_ – i.e., where assumption 2 is violated
– and probably they are not. Almost all game-theoretic treatments of (parts of)
the Bitcoin protocol deliver negative results. Many attacks against specific
cryptocurrency system designs are known to be profitable in expectation, such as
[ransaction withholding](https://www.avivz.net/pubs/12/Bitcoin_EC0212.pdf),
[empty block mining](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2407834),
[selfish mining](https://www.cs.cornell.edu/~ie53/publications/btcProcFC.pdf),
[block withholding](http://webee.technion.ac.il/people/ittay/publications/btcPoolsSP15.pdf),
[stubborn mining](https://www.cs.umd.edu/~kartik/papers/5_stubborn_eclipse.pdf),
[fork after withholding](https://syssec.kaist.ac.kr/pub/2017/kwon_ccs_2017.pdf),
and [whale attacks](http://www.cs.umd.edu/~jkatz/papers/whale-txs.pdf). It is
likely thanks only to frictions such as risk aversion and other costs that we
rarely observe such attacks in large deployed systems. Many specific attacks do
not even depend on assumption 1, underlining the fact that rationality is not a
silver bullet even where this metacircular argument does not apply. Where it
does apply, it is more general and effectively _guarantees_ the existence of
attacks against _all_ open systems that assume participants are rational.

Another related observation is that financial markets on derivatives of a system
_S_ mature in the external world (e.g., _S'_) as _S_ grows and becomes more
relevant. So in some sense, systems built on the rationality assumption are
temporarily more secure only until they become fat enough targets to be eaten by
their own success. We can see this effect, for example, in the growing and
increasingly liquid market for hash power, which effectively thwarts
[Nakamoto’s](https://bitcoin.org/bitcoin.pdf)
([or Dwork’s](https://link.springer.com/chapter/10.1007/3-540-48071-4_10)) rule
of thumb that the ratio of processors to individuals varies in a small band.
Such dynamics happen in the real world, too. But there they have traditionally
taken centuries or decades while in cryptocurrency space everything happens in
time-lapse.

## Limitations of the Argument

This argument is of course currently only a rough and informal sketch. An
enterprising student might wish to try formalizing it, or maybe someone has
already done so but we are unaware of it.

The metacircular argument certainly does not apply to all cryptocurrencies or
decentralized systems. In a permissioned system, for example, in which a closed
group of participants are strongly-identified and subject to legal and
contractual agreements with each other, one can hope that the threat of lawsuits
for arbitrarily-large damages will keep rational participants incentivized to
behave correctly. Similarly, in a national cryptocurrency, which might be
relatively open but only to citizens of a given country, and which require
verified identities with which the police can expect to track down and jail
misbehaving participants, this metacircular argument does not necessarily apply.

Apart from police enforcement, rationality assumptions may be weakened in other
ways to circumvent the metacircular argument. For example, an open system might
be designed according to a “weak rationality” assumption that users need
incentives to join the system in the first place (e.g., mining rewards in
Bitcoin), but that after having become stakeholders, most will then behave
honestly. In this case, rational incentives serve only as a tool for system
growth, but become irrelevant and equivalent to a strong honesty assumption in
terms of the internal security of the system itself.

## Conclusion: Irrationality Can Be Rational

![Types of adversaries](https://bford.info/2019/09/23/rational/adversaries-open.svg)

What many in the cryptocurrency community seem to want is a system that is both
permissionless and tolerant of strongly-rational behavior – either beyond the
thresholds a similar a Byzantine system would tolerate (such as a rational
majority), or by deriving some simplicity or efficiency benefit from assuming
rationality. But in an open world in which the permissionless system is not the
only game in town, a potential _perfectly rational_ attacker can always exist,
or appear at any time, whose entirely rational behavior is precisely to profit
from bringing the system down by violating its assumptions on participant
behavior.

So if you think you have designed a permissionless decentralized system that is
cleverly secured based on rationality assumptions, you haven't. You have merely
obfuscated the rational attacker's motive and opportunity to profit outside your
system from breaking your rationality assumptions. The only practical way to
eliminate this threat appears to be either to close the system and require
strong identities and police protection, or else secure the system against
arbitrary Byzantine behavior, thereby rendering rationality assumptions
redundant and useless for security.

> _We wish to thank Jeff Allen, Ittay Eyal, Damir Filipovic, Patrik Keller,
> Alexander Lipton, Andrew Miller, and Haoqian Zhang for helpful feedback on
> early drafts of this post._
>
> _Updated 27-Oct-2019 with link to
> [PDF preprint](https://arxiv.org/pdf/1910.08820.pdf) version._
