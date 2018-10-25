import XCTest
import Cuckoo
@testable import Bank

class WalletManagerTests: XCTestCase {
    private var mockAdapterFactory: MockIAdapterFactory!
    private var mockBitcoinAdapter: MockIAdapter!
    private var mockEthereumAdapter: MockIAdapter!

    private var manager: WalletManager!

    private let bitcoin = "BTC"
    private let ether = "ETH"

    private let words = ["one", "two"]
    private var enabledCoins: [String]!

    override func setUp() {
        super.setUp()
        enabledCoins = [bitcoin, ether]

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
        manager.initWallets(words: words, coins: enabledCoins)

        XCTAssertEqual(manager.wallets[0].coin, enabledCoins[0])
        XCTAssertEqual(manager.wallets[1].coin, enabledCoins[1])
        XCTAssertTrue(manager.wallets[0].adapter === mockBitcoinAdapter)
        XCTAssertTrue(manager.wallets[1].adapter === mockEthereumAdapter)
    }

    func testInitWallets_WithoutAdapter() {
        stub(mockAdapterFactory) { mock in
            when(mock.adapter(forCoin: bitcoin, words: equal(to: words))).thenReturn(nil)
        }

        manager.initWallets(words: words, coins: enabledCoins)

        XCTAssertEqual(manager.wallets.count, 1)
    }

    func testInitWallets_StartAdapters() {
        manager.initWallets(words: words, coins: enabledCoins)

        verify(mockBitcoinAdapter).start()
        verify(mockEthereumAdapter).start()
    }

    func testInitWallets_WithoutWords() {
        stub(mockAdapterFactory) { mock in
            when(mock.adapter(forCoin: bitcoin, words: equal(to: [String]()))).thenReturn(nil)
            when(mock.adapter(forCoin: ether, words: equal(to: [String]()))).thenReturn(nil)
        }

        manager.initWallets(words: [], coins: enabledCoins)

        XCTAssertEqual(manager.wallets.count, 0)
    }

    func testRefreshWallets() {
        manager.initWallets(words: words, coins: enabledCoins)
        manager.refreshWallets()

        verify(mockBitcoinAdapter).refresh()
        verify(mockEthereumAdapter).refresh()
    }

    func testClearWallets() {
        manager.initWallets(words: words, coins: enabledCoins)
        manager.clearWallets()

        verify(mockBitcoinAdapter).clear()
        verify(mockEthereumAdapter).clear()
        XCTAssertEqual(manager.wallets.count, 0)
    }

}
