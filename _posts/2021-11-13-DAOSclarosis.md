---
title: DAOsclerosis
subtitle: on the persistence of faulty models in governance
tags: [ethereum, blockchain, distributed computing, dao, governance]
---

# DAOsclarosis

### on the persistence of faulty models in governance

> **Demosclerosis isn’t a problem you solve It’s a problem you manage.**
> Jonathan Rauch,   
> DEMOSCLEROSIS  
> The Silent Killer of American Government, 1994

#### The DAO Corollary

> F.K.A. Amdahl’s Corollary

The most efficient way to implement a piece of software is to do it all
yourself.

No time is wasted communicating (or arguing); everything that needs to be done
is done by the same person, which increases their ability to maintain the
software; and the code is by default way more consistent.

Turns out “more efficient (_alt_ `effective`)” doesn’t mean “faster (both in
performance and time to delivery)”. When there are more people working on the
same problem, we can parallelize more at once.

When we break work up across a team, in order to optimize for the team, we often
have to put _more_ work in, individually, to ensure that the work can be
efficiently parallelized. This includes explaining concepts, team meetings, code
review, pair programming, etc. But by putting that work in, we make the work
more parallelized, speeding up and allowing us to make greater gains in the
future.

## Amdahl’s Law

Amdahl’s law can be formulated as follows:

$$
S_{\text {latency }}=\frac{1}{(1-p)+\frac{p}{s}}
$$

In other words, it predicts the maximum potential speedup (Slatency), given a
proportion of the task, p, that will benefit from improved (either more or
better) resources, and a parallel speedup factor, s.

To demonstrate, if we can speed up 10% of the task (p\=0.1) by a factor of 5
(s\=5), we get the following:

$$
S_{\text {latency }}=\frac{1}{(1–0.1)+\frac{0.1}{5}} \approx 1.09
$$

That’s about a 9% speedup — Acceptable.

However, if we can speed up 90% of the task (p\=0.9) by a factor of 5 (s\=5), we
get the following:

$$
S_{\text {latency }}=\frac{1}{(1–0.9)+\frac{0.9}{5}} \approx 3.58
$$

That’s roughly a 250% increase! Big enough that it’s actually worth creating
twice as much work; it still pays off, assuming the value of the work dwarfs the
cost of the resources.

$s \rightarrow \infty$, which means $\frac{p}{s} \rightarrow 0$, so we can also
drop the $\frac{p}{s}$ term if we can afford potentially infinite resources at
no additional cost.

$$
S_{\text {latency }}=\frac{1}{1–0.9}=10
$$

In other words, if 90% of the work can be parallelised, we can achieve a
theoretical maximum speedup of 10x, or a 900% increase. This is highly unlikely,
but gives us a useful upper bound to help us identify where the bottleneck lies.

## Generalizing a PID to the amount of `work`

Typically, we start off with a completely serial process. In order to
parallelize, we need to do _more_ work. It doesn’t come for free.

This means that when computing $s$, **the parallel speedup**, we should divide
it by the **cost of parallelization**.

For example, if the cost is _2,_ that means that making the work
_parallelisable_ (without actually increasing the number of resources) makes the
parallel portion take twice as long as it used to. (The **serial** portion is
unchanged.)

So, if we take the example from earlier, where 90% of the work is parallelisable
_but_ it costs twice as much to parallelized, we’ll get the following result:

$$
S_{\text {latency }}=\frac{1}{(1–0.9)+\frac{0.9}{\frac{5}{2}}} \approx 2.18
$$

It’s still about a $117 \%$ increase in output!  
However, if $p=0.1$, then there’s really very little point in adding more
resources.

$$
S_{\text {latency }}=\frac{1}{(1–0.1)+\frac{0.1}{\frac{5}{2}}} \approx 1.06
$$

And if the cost of parallelisation is greater than the potential speedup, bad
things happen:

$$
S_{\text {latency }}=\frac{1}{(1–0.1)+\frac{0.1}{\frac{5}{20}}} \approx 0.769
$$

Adding 4 more resources slows us down by 23%. Many of us have seen this happen
in practice with poor parallelization techniques — poor usage of locks, resource
contention (especially with regards to I/O), or even redundant work due to
mismanaged job distribution.

## So, What Does It All Mean?

Amdahl’s law tells us something very insightful:

> **When the value of your work is much greater than the cost, you should
> optimize for parallelism, not efficiency**.

The cost of a weekly two-hour team meeting is high (typically in the $1000s each
time), but if it means that you can have 7 people on the team, not 3, it’s often
worth it.

[Delivering faster means you can deliver more.](<[https://en.wikipedia.org/wiki/Gustafson's_law](https://en.wikipedia.org/wiki/Gustafson%27s_law)>)

Better to have 10 people working on 5 problems and doing a better job than it is
to have 10 people working on 10 problems.

The former will lead to fewer conflicts, fewer defects and a much more motivated
team. I.e. $p$ and $s$ produce greater returns, faster than the amount of work.

Conversely, if all the knowledge of how the product works is in one person’s
head, $p≈0$. While there’s no impact to efficiency this way, it limits our
ability to produce, because one person can only do so much. Adding more people
just makes things slower.

## **Proposal**

We introduce a proposal to replace the current regime of quorum based on-chain
voting with a new voting regime: Majordomo.

Majordomo is a tribute based governance system. In exchange for delegation of
governance voting rights, a _tribute_ is paid to secure this right. There is no
opt-out of delegation. The _majordomo_ regulates protocol parameters as well as
appoints _tribunes_ through a _patronage_ system. A patronage system is the
mechanism of dispensing grants or favors to an address (i.e. a person or
persons). Grants can be currency, privilage (e.g. privilaged access to a
non-public protocol feature), grants of patent (e.g. extending a franchise right
to establish a subsidiary on another chain), etc.

## **Background**

## **Motivation**

This is the problem statement. This is the **why** of the YIP. It should clearly
explain _why_ the current state of the protocol is inadequate. It is critical
that you explain why the change is needed. For instance, if the YIP proposes
changing how something is calculated, you must address why the current
calculation is inaccurate or wrong. This section may also include why certain
design choices were made over others, and can include data from previous
discussions and forum posts.

## **Specification**

## Axiom: Institutions are defined as stable patterns for regulating human behavior.

In an opt-in organization like a DAO, a constitution serves as a contract for
participation—by participating, one implicitly or explicitly agrees to abide by
the organization’s constitution. By regulating decision-making in an
organization, constitutions help us set the rules for how we make rules, modify
existing institutions, and even design new institutions. Good constitutions help
institutions adapt to new circumstances, new memberships, and even new code
(e.g. if any underlying smart contracts are changed).

---

> _Components of an Institution, its Constitution and Technological
> Infrastructure/Tools_

**![|641.2137931034482x388.9736842105263](https://lh5.googleusercontent.com/c2iCpCsmwET4kQ9Oyn4LzTpllGsmtHLj7qpa8f2Fi0U7EAHiVaPCB43lQO8ClVWDSC0naLo0lxloOr0rbNHDbpyzwWsfsVAVuAn-fDiJ0QKSORxmX_iREglQ3BYZqOui8HL7U1ND)**

### Defining Patterns

We use the term "pattern" meaning relevant to our protocol, and "anti-pattern"
to represent a more subjective interpretation or one that is hard to automate to
determine should it be included or not.

#### Patterns

Proposals that addresses a problem that has not been defined Proposals that
addresses a problem that no longer exists The Proposals addresses more than one
problem Proposals that has no stated purpose The language of the Proposals is
vague or complex Proposals is unable to achieve its stated goal

## Viable Governance at Scale

### Axioms and Principles

- Requirements (the need for a new law) is realized by Principle (the to-be law)

- If you are in the business of producing laws, then the law is a Business
  Object

![](https://i.imgur.com/GyzuuBU.png)

- Legal elements are not _passive_.

- This document does not seek to define an _imperative_ set but rather
  _relational_ sets.

## Legal Patterns for Finding Important Laws

We use the term "pattern" meaning relevant to our protocol, and “anti-pattern”
to represent a more subjective interpretation or one that is hard to automate to
determine should it be included or not.

## Systems Based Approach

![](https://i.imgur.com/gzsSccc.png)

### Patterns

- Law that addresses a problem that has not been defined
- Law that addresses a problem that no longer exists
- The law addresses more than one problem
- Law that has no stated purpose
- The language of the law is vague or complex
- Law is unable to achieve its stated goal

### Anti-Patterns

- Laws that address problems that have not been defined
- Laws that address problems that no longer exist
- Laws that address more than one problem in different domains
- Laws that lack a stated, measurable problem solving the goal, or purpose
- Laws that fail to achieve their goal or lack stated goals
- Laws that lack a citation of references
- Laws whose burdens are greater than their problem-solving benefit
- Laws whose problem-solving benefit and burdens are equal
- Laws whose results cannot be measured
- Laws that interfere with other laws
- Laws that duplicate other laws
- Requires Review
- Laws that are not enforced\*
- Laws that are overly vague or complex\*
- Laws that have not undergone QA analysis within a specified time frame

## Legal Primitives for Smart Contract Events / Emits

Now that we have established legal patterns and a legal classified, we can begin
to map out how these relationships present themselves, either by acting upon,
being acted upon, events, etc.

### Primitves Layer

Primitives List of Legal Primitive Mechanisms PrimitiveEvent ExercisePrimitive
AllocationPrimitive ContractFormationPrimitive ExecutionPrimitive
InceptionPrimitive ObservationPrimitive QuantityChangePrimitive ResetPrimitive
TermsChangePrimitive TransferPrimitive

## MajorDomo

Moderation is not an ideology. It is not an opinion. It is not a thought. It is
an absence of thought In other words, the problem with moderation is that the
"center" is not fixed. It moves. And since it moves, and people being people,
people will try to move it. This creates an incentive for violence, but we
should not look at this as a moral problem, rather as an engineering problem.
Any solution that solves the problem is acceptable. Any solution that does not
solve the problem is not acceptable.[^5]

sing a coinvote in this manner legitimizes any outcome of the community process,
and \[provides a convenient
default\](https://pagefair.com/blog/2015/the-tyranny-of-the-default/) for users
to converge on. Otherwise phrased, most users will likely accept most outcomes
of most coinvotes, so rigging such votes can allow a malicious actor to impose
their will on an ecosystem where the majority of honest actors disagree (but
follow along anyway, because the vote appears clean).  This, along with the
direct benefit provided by many consensus rule changes to actors within the
system (consider for example the setting of block rewards, or the setting of
block size / participation hardware requirements, or the setting of minimum
stake, etc.) means that tampering with such votes is often directly financially
incentivized.

> Populations will accept vote outcomes regardless of how bitterly they disagree
> with the outcome or how nonsensical it seems… if they accept the process.

> deciding whether there is an attack in the presence of a credible threat is a
> non-trivial social consensus problem vulnerable to false flag attacks to stall
> progress.

### Glowing in the dark

Glowing in the dark, flying or sewn into the story with phosphorescent thread.
In other words, infiltrators being spotted. Or being so obvious in their work
that it may be impossible not to spot them. Infiltrators have been a thing since
humanity started forming groups and the notion of counter-intelligence is as old
as humanity itself [^4]. This remains a credible threat especially in systems
that depend only on capital (i.e token holdings) to determine voting weight.

We can conclude that on-chain token-based voting systems essentially emulate
plutocracy.  If they do not directly emulate plutocracy, perhaps through some
external system of identity, they can be made to emulate plutocracy through the
buying and selling of constraints on user actions.

Schemes like quadratic voting, that have been proposed in a blockchain context,
explicitly allow vote buying and attempt to mitigate its impact through an
identity-based scheme.  Such schemes may have unforeseen properties in a
blockchain environment, where identity is a murky concept

It is unlikely that schemes that work well for in-person voting, boardroom
meetings, or even coordinator-based protocols will simply port to blockchains
without substantial additional work on defining and proving adversarial
resilience to both technical and economic attacks in a blockchain-specific
context.

It is clear that applying mechanisms that work in traditional information
sciences or economics is not sufficient to analyze and represent the equilibria
that will actually emerge when a given game is deployed (and matures to
importance) in a permissionless blockchain environment.

###### tags: `DAO` `Legal`

**Definition: A condition A is said to be necessary for a condition B, if (and
only if) the falsity (/nonexistence /non-occurrence) [as the case may be] of A
guarantees (or brings about) the falsity (/nonexistence /non-occurrence) of B.**

**Definition of "sufficient condition** Definition: A condition A is said to be
sufficient for a condition B, if (and only if) the truth (/existence
/occurrence) [as the case may be] of A guarantees (or brings about) the truth
(/existence /occurrence) of B.

[^4, What Glowies Mean: Online Spies, The Atlantic](https://www.theatlantic.com/politics/archive/2021/01/what-glowies-mean-online-spies/617717/)

[^5] Curtivs Yavin, Formalist Manifesto

- [Affective Priming in Political Campaigns: How Campaign-Induced Emotions Prime Political Opinions](https://academic.oup.com/ijpor/article-abstract/23/4/485/708041?redirectedFrom=fulltext)

- [The Law of Deliberative Democracy: Seeding the Field](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2367870)

- [The Left’s Next Culture War: Using Corporate Rating Indexes](https://capitalresearch.org/article/the-lefts-next-culture-war-part-2/)
