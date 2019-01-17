import XCTest
import Cuckoo
@testable import Bank_Dev_T

class SettingsProviderMapTests: XCTestCase {
    private let bitcoinProviderNames = ["HorizontalSystems.xyz", "BlockChair.com", "BlockExplorer.com", "Btc.com"]
    private let bitcoinCashProviderNames = ["HorizontalSystems.xyz", "BlockChair.com", "BlockExplorer.com", "Btc.com"]
    private let ethereumProviderNames = ["HorizontalSystems.xyz", "Etherscan.io", "BlockChair.com"]

    private var providerMap: SettingsProviderMap!
    override func setUp() {
        super.setUp()

        providerMap = SettingsProviderMap()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testProviders() {
        var providerNames = providerMap.providers(for: "BTC").map { $0.name }
        XCTAssertEqual(providerNames, bitcoinProviderNames)

        providerNames = providerMap.providers(for: "BCH").map { $0.name }
        XCTAssertEqual(providerNames, bitcoinCashProviderNames)

        providerNames = providerMap.providers(for: "ETH").map { $0.name }
        XCTAssertEqual(providerNames, ethereumProviderNames)
    }

    func testBitcoinProviders() {
        let providers = SettingsProviderMap.bitcoinProviders

        for (index, provider) in providers.enumerated() {
            XCTAssertEqual(providerMap.bitcoin(for: bitcoinProviderNames[index]).name, provider.name)
        }
    }

    func testBitcoinCashProviders() {
        let providers = SettingsProviderMap.bitcoinCashProviders

        for (index, provider) in providers.enumerated() {
            XCTAssertEqual(providerMap.bitcoinCash(for: bitcoinCashProviderNames[index]).name, provider.name)
        }
    }

    func testEthereumProviders() {
        let providers = SettingsProviderMap.ethereumProviders

        for (index, provider) in providers.enumerated() {
            XCTAssertEqual(providerMap.ethereum(for: ethereumProviderNames[index]).name, provider.name)
        }
    }


}
