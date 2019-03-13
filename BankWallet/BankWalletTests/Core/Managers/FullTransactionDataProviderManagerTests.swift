import XCTest
import Cuckoo
@testable import Bank_Dev_T

class FullTransactionDataProviderManagerTests: XCTestCase {
    private let bitcoinProviderNames = ["HorizontalSystems.xyz", "BlockChair.com", "BlockExplorer.com", "Btc.com"]
    private let bitcoinCashProviderNames = ["HorizontalSystems.xyz", "BlockChair.com", "BlockExplorer.com", "Btc.com"]
    private let ethereumProviderNames = ["Etherscan.io", "HorizontalSystems.xyz", "BlockChair.com"]

    private var mockLocalStorage: MockILocalStorage!
    private var mockAppConfigProvider: MockIAppConfigProvider!

    private var manager: IFullTransactionDataProviderManager!

    private let firstName = "Btc.com"
    private let secondName = "HorizontalSystems.xyz"

    private var firstProvider: MockIProvider!
    private var secondProvider: MockIProvider!
    private var providers: [IProvider]!

    override func setUp() {
        super.setUp()


        firstProvider = MockIProvider()
        stub(firstProvider) { mock in
            when(mock.name.get).thenReturn(firstName)
        }
        secondProvider = MockIProvider()
        stub(secondProvider) { mock in
            when(mock.name.get).thenReturn(secondName)
        }
        providers = [firstProvider, secondProvider]

        mockLocalStorage = MockILocalStorage()
        mockAppConfigProvider = MockIAppConfigProvider()

        stub(mockLocalStorage) { mock in
            when(mock.baseBitcoinProvider.get).thenReturn(firstName)
            when(mock.baseEthereumProvider.get).thenReturn(secondName)
            when(mock.baseBitcoinProvider.set(any())).thenDoNothing()
            when(mock.baseEthereumProvider.set(any())).thenDoNothing()
        }
        stub(mockAppConfigProvider) { mock in
            when(mock.testMode.get).thenReturn(false)
        }

        manager = FullTransactionDataProviderManager(localStorage: mockLocalStorage, appConfigProvider: mockAppConfigProvider)
    }

    override func tearDown() {
        mockLocalStorage = nil

        manager = nil

        super.tearDown()
    }

    func testProviders() {
        var providerNames = manager.providers(for: Coin(title: "", code: "", type: .bitcoin)).map { $0.name }
        XCTAssertEqual(providerNames, bitcoinProviderNames)

        providerNames = manager.providers(for: Coin(title: "", code: "", type: .bitcoinCash)).map { $0.name }
        XCTAssertEqual(providerNames, bitcoinCashProviderNames)

        providerNames = manager.providers(for: Coin(title: "", code: "", type: .ethereum)).map { $0.name }
        XCTAssertEqual(providerNames, ethereumProviderNames)
    }

    func testTestProviders() {
        stub(mockAppConfigProvider) { mock in
            when(mock.testMode.get).thenReturn(true)
        }
        var providerUrls = manager.providers(for: Coin(title: "", code: "", type: .bitcoin)).map { $0.url(for: "test") }
        XCTAssertEqual(providerUrls, ["http://btc-testnet.horizontalsystems.xyz/apg/tx/test"])

        providerUrls = manager.providers(for: Coin(title: "", code: "", type: .bitcoinCash)).map { $0.url(for: "test") }
        XCTAssertEqual(providerUrls, ["http://bch-testnet.horizontalsystems.xyz/apg/tx/test"])

        providerUrls = manager.providers(for: Coin(title: "", code: "", type: .ethereum)).map { $0.url(for: "test") }
        XCTAssertEqual(providerUrls, ["http://eth-testnet.horizontalsystems.xyz/tx/test"])
    }

    func testBaseProvider() {
        var baseProviderName = manager.baseProvider(for: Coin(title: "", code: "", type: .bitcoin)).name
        XCTAssertEqual(baseProviderName, firstName)

        baseProviderName = manager.baseProvider(for: Coin(title: "", code: "", type: .bitcoinCash)).name
        XCTAssertEqual(baseProviderName, firstName)

        baseProviderName = manager.baseProvider(for: Coin(title: "", code: "", type: .ethereum)).name
        XCTAssertEqual(baseProviderName, secondName)
    }

    func testSetBaseProvider() {
        let name = "test_provider"
        manager.setBaseProvider(name: name, for: Coin(title: "", code: "", type: .bitcoin))
        verify(mockLocalStorage).baseBitcoinProvider.set(equal(to: name))

        manager.setBaseProvider(name: name, for: Coin(title: "", code: "", type: .ethereum))
        verify(mockLocalStorage).baseEthereumProvider.set(equal(to: name))
    }

    func testBitcoinProviders() {
        let providers = manager.providers(for: Coin(title: "", code: "", type: .bitcoin))

        for (index, provider) in providers.enumerated() {
            XCTAssertEqual(manager.bitcoin(for: bitcoinProviderNames[index]).name, provider.name)
        }
    }

    func testBitcoinCashProviders() {
        let providers = manager.providers(for: Coin(title: "", code: "", type: .bitcoinCash))

        for (index, provider) in providers.enumerated() {
            XCTAssertEqual(manager.bitcoinCash(for: bitcoinCashProviderNames[index]).name, provider.name)
        }
    }

    func testEthereumProviders() {
        let providers = manager.providers(for: Coin(title: "", code: "", type: .ethereum))

        for (index, provider) in providers.enumerated() {
            XCTAssertEqual(manager.ethereum(for: ethereumProviderNames[index]).name, provider.name)
        }
    }

}
