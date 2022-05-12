---
title: ' The Mythical Web3 Developer Experience'
version: 2022.05.10
excerpt: 'Integrating OpenMEV into Sushiswap's Web3 DApp'
author: @aldoborrero (Aldo Borrero), @sambacha (Sam Bacha);
---
# The Mythical Web3 Developer Experience

[TOC]
- [The Mythical Web3 Developer Experience](#the-mythical-web3-developer-experience)
  * [Introduction](#introduction)
  * [What is the base implementation](#what-is-the-base-implementation)
  * [MetaMask](#metamask)
    + [Current flow](#current-flow)
    + [Previous Solution: Trick MetaMask checks for Network Id](#previous-solution--trick-metamask-checks-for-network-id)
    + [Alternative Solution: Sign the tx ourselves](#alternative-solution--sign-the-tx-ourselves)
  * [WalletConnect](#walletconnect)
    + [Current flow](#current-flow-1)
    + [Alternative Approach: Sign the tx ourselves](#alternative-approach--sign-the-tx-ourselves)
  * [Conclusions](#conclusions)
  * [Once more unto the breach](#once-more-unto-the-breach)
  * [How Sushi's is handling connectors](#how-sushi-s-is-handling-connectors)
  * [The issue with `eth_sign`, `personal_sign` and `signedTypeData_v4`](#the-issue-with--eth-sign----personal-sign--and--signedtypedata-v4-)
  * [Where does this leave us right now?](#where-does-this-leave-us-right-now-)


> Engineering UX hurdles encountered in Web3 


Note: This is a summary of internal GitHub tickets and discussions in the form of a blog post.

## Introduction

This ticket has been created with the sole purpose of discussing current issues discovered while trying to integrate our JSON RPC endpoint within SushiSwap and the different wallet providers. The idea is to have clear once and for all, what the limitations are, what we can do to overcome them and if we need to request guidance from the Sushi team.

To achieve that, I've taken the following approach as described below:

- Describe how things currently work in terms of Sushi's front-end implementation for all providers.
- Describe how the workflow works for MetaMask, what we had tried previously to overcome limitations and the remaining issues with this implementation.
- Describe how the workflow works for WalletConnect, what we had tried previously to overcome limitations and the remaining issues with this implementation.
- Conclusions

Without further ado, let's dive in.

## What is the base implementation

In a perfect world, ideally in Sushi's front-end, we would like to change the RPC endpoint definition and use ours, like this:

![image](https://user-images.githubusercontent.com/82811/145994476-989245b2-058e-4bc8-bafc-3f7b3267524b.png)

Theoretically, by just changing the RPC provider for the networks we are interested in, all transactions should be routed to that defined RPC endpoint... but it's not the case, as we all already know. So changing this value will only make the UI request generic information like the current block number and several batched calls.

The code that is responsible for doing that in Sushi's is the implementation of `NetworkConnector` and `MiniRpcProvider`:

> UPDATE (2022.05.07): This entire RPC Module was replaced, you can find the extracted code here: https://github.com/manifoldfinance/libsushi



![image](https://user-images.githubusercontent.com/82811/146026549-8d2af937-af5c-4f97-9a07-616f6903f32b.png)

Right now, in Sushi's front-end, whenever a user decides to Swap a pair of Tokens, [the current implementation can be located in `useSwapCallback`](https://github.com/sushiswap/sushiswap-interface/blob/canary/src/hooks/useSwapCallback.ts). That file, in general terms, is responsible for making such important action. So, for example, the code responsible for creating the transaction and broadcasting to the network can be seen in the screenshot below:

![image](https://user-images.githubusercontent.com/82811/145996172-1f3946aa-014f-4455-849d-0d68b65f8805.png)

As we can notice from the screenshot above, Sushi's front-end obtains a reference to the `library.getSigner()`, which is a Wallet connector that refers back to a specific implementation (like MetaMask, WalletConnect, Portis, etc.), populates the transaction information retrieved from the UI, leaves to the specific implementation to fill remaining details and if everything goes well sends the transaction to the network.

In general, we can simplify the code to be something like:

```javascript
library
  .getSigner()
  .sendTransaction({ ...tx }) // Tx is populated with real information from the user
  .then() // The hash is added to the UI that keeps polling for the TX
  .error() // If something wrong happens, like the user cancelling the TX or any other kind of error, it's being handled here
``` 
And this is the common ground for all wallet providers. So let's move now to specific implementations.

## MetaMask

### Current flow

In the case of MetaMask, the flow is the following:

The user is connected with MetaMask:

![image](https://user-images.githubusercontent.com/82811/145997849-a108199c-c6e1-41df-bd4a-52eeaec1f1cd.png)

And wants to swap these tokens for a specific amount:

![image](https://user-images.githubusercontent.com/82811/145998002-bd773f01-8411-446f-aa05-a50af6de584f.png)

A new pop-up appears showcasing MetaMask's modal for sending a Transaction:

![image](https://user-images.githubusercontent.com/82811/145998229-6e103b67-7cbb-43b9-a8be-71a765039e9d.png)

In there, the user is able, among other things, to **edit the estimated gas fee** (if he wants to, it's an entirely optional step):

![image](https://user-images.githubusercontent.com/82811/145998346-cbf834d5-f3fa-4f85-ad9f-38ff7583bd45.png)

And once he is happy, he can proceed to send the transaction to the network by using MetaMask's Infura default RPC endpoint for `mainnet`.

**Known Facts for MetaMask**:

* We already know their default Ethereum `mainnet` RPC provider uses their Infura connection.
* We also already know they don't allow us to use their [RPC method `wallet_addEthereumChain`](https://docs.metamask.io/guide/rpc-api.html#other-rpc-methods) if the network conflicts with one of their defined set of networks (i.e.: `mainnet`).

### Previous Solution: Trick MetaMask checks for Network Id

In issue #880 we were researching a potential alternative solution to trick MetaMask to believe the network we were adding was not for `mainnet`, but a completely random one.

The flow was designed to incite the user to switch to our RPC endpoint by placing a prominent button and using a custom `InjectedConnector` in charge of tricking MetaMask to believe we weren't adding network for `mainnet`. 

[This was the original comment thread](https://github.com/manifoldfinance/backbone-platform/issues/880#issuecomment-945977093) where I give a very detailed explanation on how it works, and below there are the key points and screenshots of that flow:

![image](https://user-images.githubusercontent.com/82811/137774088-b9c336c1-576d-418f-8508-2e3320e34601.png)

If it's the first time the user is adding our network, it will try to add the network:

![image](https://user-images.githubusercontent.com/82811/137774282-5a7041c4-c515-4901-8448-cef032db8204.png)

And switch to it:

![image](https://user-images.githubusercontent.com/82811/137774406-af492a01-c894-4081-83a6-53767cbbef75.png)

As it turned out, Sushi didn't want to add the Manifold button to switch/add our RPC network. Without that, there's no point of using the `InjectedConnector` anymore as it was designed only for handling that particular case and **nothing else**. 

In this aspect, **it's better to suggest the user use our RPC endpoint via a pop-up or something more prominent** as adding manually a network that overrides `mainnet` is possible (BUT ONLY IF THE USER DOES IT). We can see it in the screenshot below:

![image](https://user-images.githubusercontent.com/82811/136415403-07edd59b-332d-4b35-9171-e7d244194375.png)

### Alternative Solution: Sign the tx ourselves

Back in August, we were adding support to `manifold_sendTransaction`, and we took inspiration from what ArcherDAO did on Sushi's front-end. Their implementation can be summarized as:

1) The user needs to configure the front-end to use ArcherDAO explicitly.
2) The swap UI changed accordingly to display extra information like giving the Miner tips.
3) Whenever the user sends the TX to ArcherDAO relayer if using MetaMask or any other provider, it signs the tx manually and makes a `post` request to the endpoint.

We copied the same approach for our use case, removing extra superfluous information we didn't need (back in August, we weren't a compliant RPC endpoint, and that approach worked well).

Re-using that idea, we can use it for our RPC endpoint as well, as can be seen in the following screenshots:

We add in expert settings the option to use `OpenMEV` (it can be turned on by default):

![image](https://user-images.githubusercontent.com/82811/146009734-300f0555-a0f3-4c9e-b393-d4f14d8a2051.png)

The usual sign message UI appears:

![image](https://user-images.githubusercontent.com/82811/146010260-86f5a632-5b7b-466e-afdc-f1749ae2613c.png)

The TX is relayed to Flashbots (although that one failed):

![image](https://user-images.githubusercontent.com/82811/146010435-aa06d943-c377-445a-b87a-37db0082f789.png)

The above screenshots are the actual workflow that [I implemented yesterday and refined today on this branch](https://github.com/manifoldfinance/sushiswap-interface/commit/704ad80c63c20b622944939361947bd48ef261c5#diff-686eddb0e7f6457b55065661febd02eddda11d03b5350f62fd7dc13f275a08d0R297).

There are a couple of downsides of this approach:

* The user signs a message. We can improve the UI of what's displayed on the user by using [Sign Typed Data V4 spec](https://docs.metamask.io/guide/signing-data.html#sign-typed-data-v4) that corresponds to [EIP-712](https://eips.ethereum.org/EIPS/eip-712), but I know there are incompatibilities among different wallets implementations that we can't ignore. I reckon this can be a secondary task to improve UX and not necessary for right now.
* But more importantly, we need to re-implement the whole UI to allow the user to specify particular fields like Priority, Gas Limit, Max Fee and so on that MetaMask, WalletConnect, and other wallet implementations gives us for free. **Who's going to be in charge of doing that? Would it be somebody from Sushi? There are certain aspects we need to take into consideration.** Right now, the current implementation takes default values and doesn't allow customizing anything at all.
* If we use WalletConnect to sign the message, in my tests that I conducted with Trust Wallet that implements the standard, it doesn't work correctly, and it doesn't return the signed data to the front-end (more on it's associated section).

## WalletConnect

### Current flow

After explaining everything related to MetaMask, let's rewind back and take the current implementation that is being used right now on Sushi's. As a user if I want to use WalletConnect, the flow is the following:

The user selects WalletConnect:

![image](https://user-images.githubusercontent.com/82811/146016387-4722f0ce-ad46-4a52-bb18-e728144c025b.png)

A QR code appears to be scanned:

![image](https://user-images.githubusercontent.com/82811/146016783-7b3c2c55-2030-4c1f-b51c-6c432a57909d.png)

And once everything is finished, the link is established between the Wallet and Sushi's front-end.

Now the user is able to conduct regular swap operations like below:

![image](https://user-images.githubusercontent.com/82811/145998002-bd773f01-8411-446f-aa05-a50af6de584f.png)

And in the phone wallet the following UI appears:

![photo_2021-12-14_15-30-59](https://user-images.githubusercontent.com/82811/146017656-09a28e56-f680-48e0-88f8-c523fefa15f6.jpg)

And the user is able to configure certain aspects of the TX like on MetaMask:

![photo_2021-12-14_15-31-58](https://user-images.githubusercontent.com/82811/146017767-17fbdd75-4775-4bf6-98c5-0d2d359547ca.jpg)

In terms of the implementation, in Sushi's there's a definition to use the `WalletConnectConnector`:

```typescript
const rpc = {
  [ChainId.ETHEREUM]: 'https://api.sushirelay.com/v1',
  [ChainId.ROPSTEN]: 'https://eth-ropsten.alchemyapi.io/v2/cidKix2Xr-snU3f6f6Zjq_rYdalKKHmW',
}

// mainnet only
export const walletconnect = new WalletConnectConnector({
  rpc: RPC,
  bridge: 'https://bridge.walletconnect.org',
  qrcode: true,
  supportedChainIds,
})
```

Once the link is established all RPC requests goes to our node... **all of them except sending the TX**. Neither our `eth_sendRawTransaction` or any other related rpc method is being called but despite that fact the tx is being relayed to the network and mined fine.

Below there's an screenshot of my debugging session of yesterday that displays the configuration options and clearly we can see the WalletConnect object `wc` is correctly populated with our endpoint:

![image](https://user-images.githubusercontent.com/82811/146018598-53fdf886-7d8c-4c9d-94e5-4e46f8c04b47.png)

After spending some time there are two potential scenarios that I'm considering and that I need more supporting evidence:

* Trust Wallet is ignoring the RPC endpoint purposely when using `library.getSigner().sendTransaction()` and is being sent using their preconfigured Infura / Alchemy or whatever account.
* Recently, a couple of days ago, [it has been reported that `@walletconnect/ethereum-provider` library](https://github.com/WalletConnect/walletconnect-monorepo/issues/663) (the one that under the surface Sushi is using) doesn't correctly fill the information correctly for the RPC in certain circumstances.

### Alternative Approach: Sign the tx ourselves

If, instead we take the route of signing the TX ourselves by using the same approach I described for MetaMask:

![image](https://user-images.githubusercontent.com/82811/145998002-bd773f01-8411-446f-aa05-a50af6de584f.png)

The following UI appears:

![image](https://user-images.githubusercontent.com/82811/146021787-3a8f4333-695c-41d7-9349-eee449079161.png)

The algorithm for custom signing the Tx that I explained for MetaMask works in the following way:

![image](https://user-images.githubusercontent.com/82811/146025356-409e1b5e-8627-44d8-83d4-f71c04a2e989.png)

Basically, we detect if the provider is MetaMask, if it is, therefore we must custom sign the whole tx:

```typescript
library
    .provider.request({ method: 'personal_sign', params: [hexlify(tx.getMessageToSign()), account] })
    .then((signature) => {
        const { v, r, s } = splitSignature(signature)
        // really crossing the streams here
        // eslint-disable-next-line
        // @ts-ignore
        const txWithSignature = tx._processSignature(v, arrayify(r), arrayify(s))
        return { signedTx: hexlify(txWithSignature.serialize()), fullTx }
    })
```

Otherwise, we rely on library connector implementation:

```typescript
library
    .getSigner()
    .signTransaction(fullTx)
    .then((signedTx) => {
        return { signedTx, fullTx }
    })
```

Turns out that if we use `library.getSigner().signTransaction()` the ethers implementation of WalletConnect is not implemented at all as we can see below:

![image](https://user-images.githubusercontent.com/82811/146023402-9e5802b0-1d8c-4aa8-86ea-9fea2c97196f.png)

If, by contrary, we force the code to use `library.provider.request({ method: 'personal_sign', params: [hexlify(tx.getMessageToSign()), account] })` line, the following happens UI appears:

![photo_2021-12-14_16-04-34](https://user-images.githubusercontent.com/82811/146023969-70136612-129a-4027-91de-827286b2cae7.jpg)

Which is what we want... only that when we accept that button there's no response back to Sushi's UI (neither an error or a result, so we can't react to that at all).

Caveats of this implementation:

* Same as those described for MetaMask, we should prepare the UI to allow the user to tweak tx settings.
* Potentially research, understand, involve more parties and involve more parties to see what's going on with the implementation of WalletConnect and why is behaving like that and prepare a fix (if necessary).

## Conclusions 

As I described, this only touches MetaMask and WalletConnect, I can't imagine if we need to support the other connectors. We can skip those for now, but even with that, we need to answer the questions I raised for the case of MetaMask and also those of WalletConnect if we are willing to support it at all.


## Once more unto the breach

After spending more time yesterday reading more Sushi's codebase, reading the code of WalletConnect and MetaMask, reading a couple of Github issues and conducting tests, I've solved some problems that I presented yesterday. This comment is an update of my newly acquired knowledge and the progress I have made since:

## How Sushi's is handling connectors

First and foremost, Sushi's is wrapping [`web3-react`](https://github.com/NoahZinsmeister/web3-react (the library they use to handle connectivity to different Wallet providers)) connectors into an etherjs [`Provider`](https://docs.ethers.io/v5/api/providers/) interface. We can see that here:

![image](https://user-images.githubusercontent.com/82811/146187134-5a99ecab-935f-48e2-88fa-ed1764d56f6b.png)

The function `getLibrary` is called way at the beginning of the `React App` as we can see below:

![image](https://user-images.githubusercontent.com/82811/146187323-cc6c97bf-3226-4b1d-bc3c-6d05b8410b60.png)

Now, if we take a look into the implementation of ethersjs `Web3Provider`:

![image](https://user-images.githubusercontent.com/82811/146187577-67ffd79e-ecd6-47cd-825d-77d94784be8b.png)

We can see that it extends `JsonRpcProvider`, and if we research the implementation, we discover the following:

![image](https://user-images.githubusercontent.com/82811/146187870-c029c4e0-553e-4b09-831b-186a0e5dc50e.png)

So, that explains why whenever we were using the method `library.getSigner().signTransaction()` was throwing that error. Initially, I thought it was related to exclusively to `WalletConnectConnector` implementation.

This means, we need to use directly `library.provider` implementation and use it directly without intermediaries.

## The issue with `eth_sign`, `personal_sign` and `signedTypeData_v4`

**UPDATE**: We can't use `eth_signTypedData_v4` as it adds the `\x19Ethereum Signed Message:\n42a…` prefix (as is stated here in [EIP-712](https://eips.ethereum.org/EIPS/eip-712#eth_signtypeddata)). So do `personal_sign`. We need to rely on only `eth_sign` directly. Also, for the part where I commented that TrustWallet was not answering initially, `eth_sign` was caused by my network connectivity issues with IPV6, which made me think that `eth_sign` was being ignored. Consider what you read below as practically invalid.

In this particular issue opened in etherjs repository called [Use personal_sign instead of eth_sign for JSON-RPC](https://github.com/ethers-io/ethers.js/issues/1544), there's a discussion of the state of the art for `eth_sign`, `personal_sign` and related methods. This issue is particular useful as it explains why some wallets / implementations returns errors (like we were seeing with TrustWallet not answering `eth_sign` request).

We can see what `ricmoo` [has said related to the situation](https://github.com/ethers-io/ethers.js/issues/1544#issue-877935690):

![image](https://user-images.githubusercontent.com/82811/146189613-fd8501e9-477a-4bf8-968e-8790ba5e3891.png)

User `alfetopito` [adds the following](https://github.com/ethers-io/ethers.js/issues/1544#issuecomment-833878616):

![image](https://user-images.githubusercontent.com/82811/146189791-8d5c1b8e-93f0-44f4-bb02-ad16f387e1f3.png)

So the conclusion we need to extract is:

1) As a rule of thumb, always try to use `personal_sign` method first and resort to `eth_sign`
2) `eth_signTypedData_v4` can be used in these apps securely (just mentioning this but the initial version is not going to resort on this method by any means).

![image](https://user-images.githubusercontent.com/82811/146190697-67543d33-08df-442f-b086-1240dd1185ac.png)

## Where does this leave us right now?

I updated the implementation of `useSwapCallback` to reflect these newly discovered insight:

```typescript
let txResponse: Promise<TransactionResponseLight>
        if (!useOpenMev) {
          txResponse = library.getSigner().sendTransaction({
            from: account,
            to: address,
            data: calldata,
            // let the wallet try if we can't estimate the gas
            ...('gasEstimate' in bestCallOption ? { gasLimit: calculateGasMargin(bestCallOption.gasEstimate) } : {}),
            gasPrice: !eip1559 && chainId === ChainId.HARMONY ? BigNumber.from('2000000000') : undefined,
            ...(value && !isZero(value) ? { value } : {}),
          })
        } else {
          console.log(`Use OpenMEV`, useOpenMev)

          const supportedNetwork = OPENMEV_SUPPORTED_NETWORKS.includes(chainId)
          if (!supportedNetwork) throw new Error(`Unknown chain id ${chainId} when building transaction`)

          txResponse = library
            .getSigner()
            .populateTransaction({
              from: account,
              to: address,
              data: calldata,
              // let the wallet try if we can't estimate the gas
              ...('gasEstimate' in bestCallOption ? { gasLimit: calculateGasMargin(bestCallOption.gasEstimate) } : {}),
              ...(value && !isZero(value) ? { value } : {}),
              ...(!eip1559 ? { gasPrice: 0 } : {}),
            })
            .then((txReq) => {
              console.log(`EIP1559`, eip1559)
              console.log(`FullTX`, txReq)

              const tx = TransactionFactory.fromTxData(
                {
                  type: txReq.type ? hexlify(txReq.type) : undefined,
                  chainId: txReq.chainId ? hexlify(txReq.chainId) : undefined,
                  nonce: txReq.nonce ? hexlify(txReq.nonce, { hexPad: 'left' }) : undefined,
                  gasPrice: txReq.gasPrice ? hexlify(txReq.gasPrice, { hexPad: 'left' }) : undefined,
                  gasLimit: txReq.gasLimit ? hexlify(txReq.gasLimit, { hexPad: 'left' }) : undefined,
                  maxFeePerGas: txReq.maxFeePerGas ? hexlify(txReq.maxFeePerGas, { hexPad: 'left' }) : undefined,
                  maxPriorityFeePerGas: txReq.maxPriorityFeePerGas
                    ? hexlify(txReq.maxPriorityFeePerGas, { hexPad: 'left' })
                    : undefined,
                  to: txReq.to,
                  value: txReq.value ? hexlify(txReq.value, { hexPad: 'left' }) : undefined,
                  data: txReq.data?.toString(),
                },
                {
                  common: new Common({
                    chain: chainId,
                    hardfork: 'berlin',
                    eips: eip1559 ? [1559] : [],
                  }),
                }
              )

              console.log(`TX`, tx.toJSON())

              return library.provider
                .request({ method: 'personal_sign', params: [hexlify(tx.getMessageToSign()), account] })
                .then((signature) => {
                  const { v, r, s } = splitSignature(signature)
                  // really crossing the streams here
                  // eslint-disable-next-line
                  // @ts-ignore
                  const txWithSignature = tx._processSignature(v, arrayify(r), arrayify(s))
                  return { signedTx: hexlify(txWithSignature.serialize()), fullTx: txReq }
                })
            })
            .then(({ signedTx }) => {
              const relayURI = chainId ? OPENMEV_URI[chainId] : undefined
              if (!relayURI) throw new Error(`Could not determine Sushi Relay URI for this network: ${chainId}`)

              const body = JSON.stringify({
                jsonrpc: '2.0',
                id: new Date().getTime(),
                method: 'eth_sendRawTransaction',
                params: [signedTx],
              })

              console.log(`Sending to URI: ${relayURI}`)
              console.log(`Body:`, body)

              return fetch(relayURI, {
                method: 'POST',
                body,
                headers: {
                  'Content-Type': 'application/json',
                },
              }).then((res: Response) => {
                // Handle success
                if (res.status === 200) {
                  return res.json().then((json) => {
                    // But first check if there are some errors first and throw accordingly
                    if (json.error) throw Error(`${json.error.message}`)

                    // Otherwise return a TransactionResponseLight object
                    return { hash: json.result } as TransactionResponseLight
                  })
                }

                // Generic error
                if (res.status !== 200) throw Error(res.statusText)
              })
            })
        }
```

This leaves the algorithm like:

1) If user does not have enabled OpenMEV, continue like previously.
2) If it does then:
  1) Populate the transaction information by using `library.getSigner().populateTransaction()` method
  2) Convert the resulting tx from `ethersjs` to raw by using `TransactionFactory.fromTxData` helper
  3) Send the information to be signed by the wallet, right now using `personal_sign` but we should take into account failure and retry with `eth_sign`.
  4) Send the TX to our RPC endpoint.
3) Update UI accordingly.

So far I've been testing with:

* Chrome MetaMask
* iOS MetaMask
* iOS TrustWallet 

And all of them are able to sign and send the TX to the relay. There's still some issues with Txs failing:

![image](https://user-images.githubusercontent.com/82811/146192083-b2153c3e-27ed-40b1-9612-c96e3bbf1114.png)

That I need to research why is happening whenever I have the basic flow tested and pushed to our repository.

Sushi is calculating TX gas price and other metrics by default, so as a first version where the user is not going to customize TX details like `GasPrice`, `MaxFeePerGas` and so on can work. We need still, to coordinate with them how we can create a UI that takes that into account. But one step at a time.
