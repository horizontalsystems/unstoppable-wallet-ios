import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import Testing
import TronKit
@testable import WalletCore

/// Freezes which tokens each kind of account supports, so moving a chain's rows out of
/// `AccountType.supports(token:)` into its plugin cannot change the answer. The literals were taken
/// from the code before any chain moved.
struct AccountTokenSupportParityTests {
    @Test(arguments: AccountTokenSupportSample.allCases)
    func supportedTokens(sample: AccountTokenSupportSample) throws {
        try #require(Core.instance != nil)

        let accountType = try sample.accountType()
        let supported = parityTokens
            .filter { accountType.supports(token: $0) }
            .map { TokenQuery(blockchainType: $0.blockchainType, tokenType: $0.type).id }
            .sorted()

        #expect(supported == sample.expected, "\(sample.rawValue)")
    }
}

/// One account type per `AccountType` case.
enum AccountTokenSupportSample: String, CaseIterable {
    case mnemonic
    case passkeyOwned
    case evmPrivateKey
    case trcPrivateKey
    case stellarSecretKey
    case evmAddress
    case tronAddress
    case tonAddress
    case solanaAddress
    case stellarAccount
    case xrpAddress
    case nearAddress
    case thorChainAddress
    case mayaChainAddress
    case hdExtendedKey
    case btcAddress
    case moneroWatchAccount
    case zcashViewingKey
    case moneroMnemonic

    func accountType() throws -> AccountType {
        switch self {
        case .mnemonic: return .mnemonic(words: Array(repeating: "abandon", count: 11) + ["about"], salt: "", bip39Compliant: true)
        case .passkeyOwned: return .passkeyOwned(credentialID: Data(repeating: 4, count: 16))
        case .evmPrivateKey: return .evmPrivateKey(data: Data(repeating: 2, count: 32))
        case .trcPrivateKey: return .trcPrivateKey(data: Data(repeating: 3, count: 32))
        case .stellarSecretKey: return .stellarSecretKey(secretSeed: "SECRET")
        case .evmAddress: return .evmAddress(address: EvmKit.Address(raw: Data(repeating: 1, count: 20)))
        case .tronAddress: return try .tronAddress(address: TronKit.Address(address: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"))
        case .tonAddress: return .tonAddress(address: "ton-address")
        case .solanaAddress: return .solanaAddress(address: "solana-address")
        case .stellarAccount: return .stellarAccount(accountId: "stellar-account")
        case .xrpAddress: return .xrpAddress(address: "xrp-address")
        case .nearAddress: return .nearAddress(address: "alice.near")
        case .thorChainAddress: return .thorChainAddress(address: "thorchain-address")
        case .mayaChainAddress: return .mayaChainAddress(address: "mayachain-address")
        case .hdExtendedKey: return try .hdExtendedKey(key: HDExtendedKey(extendedKey: "zpub6rFR7y4Q2AijBEqTUquhVz398htDFrtymD9xYYfG1m4wAcvPhXNfE3EfH1r1ADqtfSdVCToUG868RvUUkgDKf31mGDtKsAYz2oz2AGutZYs"))
        case .btcAddress: return .btcAddress(address: "btc-address", blockchainType: .bitcoin, tokenType: .derived(derivation: .bip84))
        case .moneroWatchAccount: return .moneroWatchAccount(address: "monero-address", viewKey: "view-key")
        case .zcashViewingKey: return .zcashViewingKey(ufvk: "uview")
        case .moneroMnemonic: return .moneroMnemonic(words: Array(repeating: "word", count: 25), passphrase: "")
        }
    }

    /// `.passkeyOwned` is empty because Unstoppable registers no `AccountTokenSupport` provider.
    var expected: [String] {
        switch self {
        case .mnemonic: [
                "arbitrum-one|eip20:0xtoken",
                "arbitrum-one|native",
                "arc|eip20:0xtoken",
                "arc|native",
                "avalanche|eip20:0xtoken",
                "avalanche|native",
                "base|eip20:0xtoken",
                "base|native",
                "binance-smart-chain|eip20:0xtoken",
                "binance-smart-chain|native",
                "bitcoin-cash|address_type:type0",
                "bitcoin-cash|address_type:type145",
                "bitcoin|derived:bip44",
                "bitcoin|derived:bip49",
                "bitcoin|derived:bip84",
                "bitcoin|derived:bip86",
                "dash|native",
                "ecash|native",
                "ethereum|eip20:0xtoken",
                "ethereum|native",
                "fantom|eip20:0xtoken",
                "fantom|native",
                "gnosis|eip20:0xtoken",
                "gnosis|native",
                "litecoin|derived:bip44",
                "litecoin|derived:bip49",
                "litecoin|derived:bip84",
                "litecoin|derived:bip86",
                "mayachain|native",
                "monero|native",
                "near-protocol|native",
                "near-protocol|near-protocol:usdt.tether-token.near",
                "optimistic-ethereum|eip20:0xtoken",
                "optimistic-ethereum|native",
                "polygon-pos|eip20:0xtoken",
                "polygon-pos|native",
                "robinhood|eip20:0xtoken",
                "robinhood|native",
                "solana|native",
                "solana|spl:spl-token",
                "stellar|native",
                "stellar|stellar:USDC-issuer",
                "the-open-network|native",
                "the-open-network|the-open-network:jetton-token",
                "thorchain|native",
                "thorchain|thorchain:denom",
                "tron|eip20:0xtoken",
                "tron|native",
                "xrp|native",
                "xrp|xrp:USD-issuer",
                "zano|native",
                "zano|zano:asset",
                "zcash|native",
                "zksync|eip20:0xtoken",
                "zksync|native",
            ]
        case .passkeyOwned: []
        case .evmPrivateKey: [
                "arbitrum-one|eip20:0xtoken",
                "arbitrum-one|native",
                "arc|eip20:0xtoken",
                "arc|native",
                "avalanche|eip20:0xtoken",
                "avalanche|native",
                "base|eip20:0xtoken",
                "base|native",
                "binance-smart-chain|eip20:0xtoken",
                "binance-smart-chain|native",
                "ethereum|eip20:0xtoken",
                "ethereum|native",
                "fantom|eip20:0xtoken",
                "fantom|native",
                "gnosis|eip20:0xtoken",
                "gnosis|native",
                "optimistic-ethereum|eip20:0xtoken",
                "optimistic-ethereum|native",
                "polygon-pos|eip20:0xtoken",
                "polygon-pos|native",
                "robinhood|eip20:0xtoken",
                "robinhood|native",
                "zksync|eip20:0xtoken",
                "zksync|native",
            ]
        case .trcPrivateKey: ["tron|eip20:0xtoken", "tron|native"]
        case .stellarSecretKey: ["stellar|native", "stellar|stellar:USDC-issuer"]
        case .evmAddress: [
                "arbitrum-one|eip20:0xtoken",
                "arbitrum-one|native",
                "arc|eip20:0xtoken",
                "arc|native",
                "avalanche|eip20:0xtoken",
                "avalanche|native",
                "base|eip20:0xtoken",
                "base|native",
                "binance-smart-chain|eip20:0xtoken",
                "binance-smart-chain|native",
                "ethereum|eip20:0xtoken",
                "ethereum|native",
                "fantom|eip20:0xtoken",
                "fantom|native",
                "gnosis|eip20:0xtoken",
                "gnosis|native",
                "optimistic-ethereum|eip20:0xtoken",
                "optimistic-ethereum|native",
                "polygon-pos|eip20:0xtoken",
                "polygon-pos|native",
                "robinhood|eip20:0xtoken",
                "robinhood|native",
                "zksync|eip20:0xtoken",
                "zksync|native",
            ]
        case .tronAddress: ["tron|eip20:0xtoken", "tron|native"]
        case .tonAddress: ["the-open-network|native", "the-open-network|the-open-network:jetton-token"]
        case .solanaAddress: ["solana|native", "solana|spl:spl-token"]
        case .stellarAccount: ["stellar|native", "stellar|stellar:USDC-issuer"]
        case .xrpAddress: ["xrp|native", "xrp|xrp:USD-issuer"]
        case .nearAddress: ["near-protocol|native", "near-protocol|near-protocol:usdt.tether-token.near"]
        case .thorChainAddress: ["thorchain|native", "thorchain|thorchain:denom"]
        case .mayaChainAddress: ["mayachain|native"]
        case .hdExtendedKey: ["bitcoin|derived:bip84", "litecoin|derived:bip84"]
        case .btcAddress: ["bitcoin|derived:bip84"]
        case .moneroWatchAccount: ["monero|native"]
        case .zcashViewingKey: ["zcash|native"]
        case .moneroMnemonic: ["monero|native"]
        }
    }
}

private let evmTypes: [BlockchainType] = [
    .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .base, .zkSync, .robinhood, .arc,
]

/// The native token of every supported chain, every derivation and address type, a token of each
/// kind on its own chain, and cross rows no account supports.
private let parityTokens: [Token] = {
    var result = BlockchainType.supported.map { token($0, .native) }

    for type in [BlockchainType.bitcoin, .litecoin] {
        result += TokenType.Derivation.allCases.map { token(type, .derived(derivation: $0)) }
    }

    result += TokenType.AddressType.allCases.map { token(.bitcoinCash, .addressType(type: $0)) }
    result += (evmTypes + [.tron]).map { token($0, .eip20(address: "0xtoken")) }

    result += [
        token(.solana, .spl(address: "spl-token")),
        token(.ton, .jetton(address: "jetton-token")),
        token(.stellar, .stellar(code: "USDC", issuer: "issuer")),
        token(.zano, .zanoAsset(id: "asset")),
        token(.thorChain, .thorChainAsset(denom: "denom")),
        token(.mayaChain, .thorChainAsset(denom: "denom")),
        token(.xrp, .xrpAsset(currency: "USD", issuer: "issuer")),
        token(.near, .nep141(contractId: "usdt.tether-token.near")),
        token(.near, .eip20(address: "0xtoken")),
        token(.ethereum, .nep141(contractId: "usdt.tether-token.near")),
        token(.solana, .nep141(contractId: "usdt.tether-token.near")),
    ]

    return result
}()

private func token(_ blockchainType: BlockchainType, _ tokenType: TokenType) -> Token {
    Token(
        coin: Coin(uid: "coin", name: "Coin", code: "COIN"),
        blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
        type: tokenType,
        decimals: 18
    )
}
