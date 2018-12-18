import XCTest
import Cuckoo
@testable import Bank_Dev_T

class WalletManagerTests: XCTestCase {
    private var mockAdapterFactory: MockIAdapterFactory!
    private var mockBitcoinAdapter: MockIAdapter!
    private var mockEthereumAdapter: MockIAdapter!

    private var manager: WalletManager!

    private let bitcoin = "BTC"
    private let ether = "ETH"

    private let words = ["one", "two"]
    private var enabledCoinCodes: [String]!

    override func setUp() {
        super.setUp()
        enabledCoinCodes = [bitcoin, ether]

        mockAdapterFactory = MockIAdapterFactory()
        mockBitcoinAdapter = MockIAdapter()
        mockEthereumAdapter = MockIAdapter()

        stub(mockAdapterFactory) { mock in
            when(mock.adapter(forCoin: bitcoin, words: equal(to: words))).thenReturn(mockBitcoinAdapter)
            when(mock.adapter(forCoin: ether, words: equal(to: words))).thenReturn(mockEthereumAdapter)
        }
        stub(mockBitcoinAdapter) { mock in
            when(mock.start()).thenDoNothing()
            when(mock.refresh()).thenDoNothing()
            when(mock.clear()).thenDoNothing()
        }
        stub(mockEthereumAdapter) { mock in
            when(mock.start()).thenDoNothing()
            when(mock.refresh()).thenDoNothing()
            when(mock.clear()).thenDoNothing()
        }

        manager = WalletManager(adapterFactory: mockAdapterFactory)
    }

    override func tearDown() {
        mockAdapterFactory = nil
        mockBitcoinAdapter = nil
        mockEthereumAdapter = nil

        manager = nil

        super.tearDown()
    }

    func testInitWallets() {
        manager.initWallets(words: words, coinCodes: enabledCoinCodes)

        XCTAssertEqual(manager.wallets[0].coinCode, enabledCoinCodes[0])
        XCTAssertEqual(manager.wallets[1].coinCode, enabledCoinCodes[1])
        XCTAssertTrue(manager.wallets[0].adapter === mockBitcoinAdapter)
        XCTAssertTrue(manager.wallets[1].adapter === mockEthereumAdapter)
    }

    func testInitWallets_WithoutAdapter() {
        stub(mockAdapterFactory) { mock in
            when(mock.adapter(forCoin: bitcoin, words: equal(to: words))).thenReturn(nil)
        }

        manager.initWallets(words: words, coinCodes: enabledCoinCodes)

        XCTAssertEqual(manager.wallets.count, 1)
    }

    func testInitWallets_StartAdapters() {
        manager.initWallets(words: words, coinCodes: enabledCoinCodes)

        verify(mockBitcoinAdapter).start()
        verify(mockEthereumAdapter).start()
    }

    func testInitWallets_WithoutWords() {
        stub(mockAdapterFactory) { mock in
            when(mock.adapter(forCoin: bitcoin, words: equal(to: [String]()))).thenReturn(nil)
            when(mock.adapter(forCoin: ether, words: equal(to: [String]()))).thenReturn(nil)
        }

        manager.initWallets(words: [], coinCodes: enabledCoinCodes)

        XCTAssertEqual(manager.wallets.count, 0)
    }

    func testClearWallets() {
        manager.initWallets(words: words, coinCodes: enabledCoinCodes)
        manager.clearWallets()

        verify(mockBitcoinAdapter).clear()
        verify(mockEthereumAdapter).clear()
        XCTAssertEqual(manager.wallets.count, 0)
    }

}
