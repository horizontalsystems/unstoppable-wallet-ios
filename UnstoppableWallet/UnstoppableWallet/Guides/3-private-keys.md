# Private Keys Explained

So, by now you know the basics behind blockchains, cryptocurrencies and wallet types. 

As we have explained, non-custodial cryptocurrency wallets provide independent storage of the cryptographic keys that have control over the coins on the wallet's balance.

From that key the wallet apps can understand the amount user owns as well as past transactions. This cryptographic key is usually referred to as private key. 

> The wallet app is an instrument that essentially stores your private key. This private key is what gives you control over certain amount of coins which cumulatively define your balance.
>
> The non-custodial wallet app uses private key to retrieve balance and past transactions.

To keep this guide simple we are not going to explain how the private keys work under the hood. Just know that a term private key usually refers to a cryptographic key we talked about earlier. 

## 1. Keep Keys Private

Quite often scammers impersonating wallet support team members trick users into sharing the private keys to steal the funds on the balance. 

Keep that in mind. There is absolutely no valid reason for you as a wallet pp user to ever share the private keys with anyone. 

Reveal your private key to someone only when you intentionally want to pass the ownership of your funds to that person.

## 2. Accessing Private Key

Any non-custodial wallet should provide means for the user to access and view private key from within the wallet app.

If that option isn't there then there is a good chance the wallet is a custodial one. Most wallet apps show the private key during the wallet app setup.

Now, we are going to be looking a bit deeper into security aspects to give you a better understanding of private keys, and the wallet security in general.

## 3. Backing Up Private Key

Many non-custodial wallets will require users to store a backup of the private keys somewhere safely offline. 
 
> The private key is the only way to restore access to funds in case the device with the wallet app become inaccessible i.e. if it gets stolen or simply stops working.

To make it easier for the average person to backup the private key, blockchain engineers came up with a way to convert the private key to a plain set of 12 or 24 regular words. 

So, most of the non-custodial wallets will display the private key in a human-readable form, generally in a form 12/24 words.

Therefore, always backup the private key and make sure there are no typos in your backup. Other than actual words, the ordering is just as important. 

> Safely storing your private key is extremely important. Failure to do so could result in a loss of your assets. If you lose or unknowingly expose the key to someone, they can get control of your crypto. That's the only thing you need to understand. The rest is secondary.

The 12/24 words should be backed up in the correct order. A non-custodial wallet may understand if you make a typo in one of the words and show an appropriate warning. 

If the words positioned incorrectly a non-custodial wallet will still restore some random wallet, it just won't be yours. So, the correct order is just as important.

## 4. Generating Private Key

When you first install and subsequently setup a non-custodial wallet app, the code powering the wallet app randomly generates a secure Private Key.

For the private key to be truly secure it's important for a wallet app to generate a private key which is truly random. If it's not random it's potentially not as safe.

> That's one of the reasons why non-custodial wallets keep the code open. If the code is open then third-party engineers can analyze it and make sure wallet does the private key generation correctly.
   
There are well documented manuals for engineers describing how to do that on a platform on which the wallet is built for.

The websites like [WalletScrutiny.com](https://walletscrutiny.com) exist to ensure that wallet's published on Google Play and App Store in fact use the same code as the code publicly shared with the community.

## 5. One Key, Many Coins

So, now you know what a private key is and how it's generated. We are almost done with the private keys just a couple of other points.

Another essential aspect you should understand is that a single private key can be used to control balances for multiple cryptocurrencies.

Restoring a single private key will essentially restore access to all balances as well as history of transactions for each coin where you had some activity.

For instance, when creating the wallet on [Unstoppable wallet](https://unstoppable.money) user gets a single private key for 5 cryptocurrencies:

- Bitcoin
- Dash
- Bitcoin Cash
- Litecoin
- Ethereum

Over time the user may end up with dozens of balances spanning a number of supported currencies. So in that regards, the same private key is used to control the balance for many cryptocurrencies.

So never reveal your private keys even if the balance on some of its coins is empty. By doing that you unintentionally hand over the control over the balance and activity of some other cryptocurrency.

## 6. Balances & Transactions

So, you might be wondering how the non-custodial wallet app can take a single private key and from that restore your balances for various currencies as well as your past transactions for each.

As was mentioned above there are 'private key' standards designed by engineers throughout the years. These standards define how exactly wallet apps should handle the private key for use with multiple cryptocurrencies. 

> When using a standard private key any well-made non-custodial wallet app can derive all addresses the wallet owner can use to receive funds, for each coin the wallet supports. 

Once the app knows the addresses for say Bitcoin, it connects to the Bitcoin blockchain and looks for transactions involving those addresses. 

As a result of that process the wallet app can display the balance and past transactions associated with that private key.

## 7. Moving Between Wallets

Moreover, good non-custodial wallets enable private key migration between wallets. In other words, a private key created on one non-custodial wallet can be used (restored) in another non-custodial wallet. 

> This means that the user is not restricted to a single wallet provider and may easily migrate between non-custodial wallets built by different parties. 

If your phone breaks, or the wallet app stops working, your funds are still safe; you will always be able to restore access to your crypto funds using the private key the wallet generated. 

There are no time frames---the same key would work years later.

Not all non-custodial wallets provide an Import (or Restore) wallet feature. When choosing a wallet you should for ones that migration/import/export of private keys between different wallets
A good breed of non-custodial wallets follow the commonly accepted standards when dealing with private keys. The private keys are set up in a way where a person can easily migrate to another wallet and vice versa.

Note that when migrating your private key from one wallet to another you need the destination wallet to support all cryptocurrencies that private key controls. 

If your private key has some balance on Bitcoin and Ethereum but the destination wallet supports only Bitcoin then your Ethereum balance won't be visible. It will still be yours and accessible from some other wallet.