import MarketKit
import Testing
@testable import WalletCore

// A watched UTXO address is named after its own network, not always BTC
struct AccountTypeBtcAddressDescriptionTests {
    @Test(arguments: [
        (BlockchainType.bitcoin, "BTC Address"),
        (.bitcoinCash, "BCH Address"),
        (.ecash, "XEC Address"),
        (.litecoin, "LTC Address"),
        (.dash, "DASH Address"),
    ])
    func descriptionNamesTheNetwork(blockchainType: BlockchainType, expected: String) {
        let accountType = AccountType.btcAddress(address: "address", blockchainType: blockchainType, tokenType: .native)

        #expect(accountType.description == expected)
    }
}
