import MarketKit
import Testing
@testable import WalletCore

// A watched UTXO address is labelled with its own network's coin, not always BTC
struct AccountTypeBtcAddressDescriptionTests {
    @Test(arguments: [
        (BlockchainType.bitcoin, "BTC"),
        (.bitcoinCash, "BCH"),
        (.ecash, "XEC"),
        (.litecoin, "LTC"),
        (.dash, "DASH"),
    ])
    func coinCodeNamesTheNetwork(blockchainType: BlockchainType, expected: String) {
        #expect(AccountType.btcAddressCoinCode(blockchainType) == expected)
    }
}
