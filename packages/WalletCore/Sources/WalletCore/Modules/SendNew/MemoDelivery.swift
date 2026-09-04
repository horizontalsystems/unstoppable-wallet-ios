import MarketKit

public extension MemoType {
    // The one question every flow that has to hand an identifier to a counterparty must ask. It is
    // NOT "does this chain have a memo field" — it is "will a memo attached here actually reach the
    // owner of the destination address, readable by them".
    //
    // A swap/private-send provider matches an incoming deposit to its order by that identifier, and
    // a deposit it cannot match is typically unrecoverable (API.txt §5), so only .onChainPublic is
    // safe to proceed on:
    //   .local          — kept on this device only, never broadcast (Monero writes it as a wallet
    //                     user note). The counterparty could never see it, yet the send would look
    //                     successful.
    //   .onChainPrivate — encrypted on-chain (Zano transfer comment, shielded Zcash memo). Whether
    //                     the counterparty decrypts and reads it is unverifiable from the client,
    //                     and the failure mode is lost funds. Relax only with evidence.
    //   .none           — no memo is carried at all (EVM, Tron, Solana, transparent Zcash).
    //
    // Do not simplify this to `!= .none`.
    var deliversAttachment: Bool {
        switch self {
        case .onChainPublic: true
        case .onChainPrivate, .local, .none: false
        }
    }
}

public extension BlockchainType {
    // How far a memo travels on a plain transfer that THIS APP builds for this chain. It is the
    // single table behind both the Private Send deposit gate and the USwap deposit builders, so the
    // two cannot drift apart; every IPreSendHandler with a chain-constant answer reads it too.
    //
    // Where a chain's answer varies by address this returns the MOST reachable of the possibilities
    // (Zcash: .onChainPrivate shielded, .none transparent), so `deliversAttachment == false` here is
    // conclusive for every address on the chain, while `true` may still need narrowing by address —
    // which is what ZcashPreSendHandler.memoType(address:) overrides to do.
    //
    // The switch is deliberately exhaustive: a chain added to MarketKit must be classified here
    // rather than silently inherit someone else's answer.
    var memoType: MemoType {
        switch self {
        // A memo becomes an OP_RETURN output, broadcast in the clear (BitcoinCore OutputSetter).
        case .bitcoin, .bitcoinCash, .ecash, .litecoin, .dash: .onChainPublic
        // Shielded memos are encrypted to the recipient; transparent addresses carry no memo at all.
        case .zcash: .onChainPrivate
        // MoneroKit stores the memo via MONERO_Wallet_setUserNote — a local note on this device's
        // wallet cache, keyed by tx id. Nothing about it is broadcast.
        case .monero: .local
        // ZanoKit passes the memo as the transfer's "comment", encrypted on-chain.
        case .zano: .onChainPrivate
        // Nothing on these paths carries a memo: EvmPreSendHandler ignores `memo` entirely, the Tron
        // and Solana handlers drop it before it reaches the transaction.
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne,
             .gnosis, .fantom, .base, .zkSync, .robinhood, .tron, .solana: .none
        // Public payloads: a TON comment, a Stellar text memo and a THORChain memo are all plainly
        // readable on-chain.
        case .ton, .stellar, .thorChain, .mayaChain: .onChainPublic
        case .unsupported: .none
        }
    }
}
