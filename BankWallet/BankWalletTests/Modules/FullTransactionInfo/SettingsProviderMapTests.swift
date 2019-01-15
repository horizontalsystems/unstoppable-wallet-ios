import XCTest
import Cuckoo
@testable import Bank_Dev_T

class SettingsProviderMapTests: XCTestCase {

    private var providerMap: SettingsProviderMap!

    override func setUp() {
        super.setUp()

        providerMap = SettingsProviderMap()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testBitcoinProviders() {
        let providers = SettingsProviderMap.bitcoinProviders
        let providerNames = ["HorizontalSystems.xyz", "BlockChair.com", "BlockExplorer.com", "Btc.com"]

        for (index, provider) in providers.enumerated() {
            XCTAssertEqual(providerMap.bitcoin(for: providerNames[index]).name, provider.name)
        }
    }

    func testBitcoinCashProviders() {
        let providers = SettingsProviderMap.bitcoinCashProviders
        let providerNames = ["HorizontalSystems.xyz", "BlockChair.com", "BlockExplorer.com", "Btc.com"]

        for (index, provider) in providers.enumerated() {
            XCTAssertEqual(providerMap.bitcoinCash(for: providerNames[index]).name, provider.name)
        }
    }

    func testEthereumProviders() {
        let providers = SettingsProviderMap.ethereumProviders
        let providerNames = ["HorizontalSystems.xyz", "Etherscan.io", "BlockChair.com"]

        for (index, provider) in providers.enumerated() {
            XCTAssertEqual(providerMap.ethereum(for: providerNames[index]).name, provider.name)
        }
    }


}
