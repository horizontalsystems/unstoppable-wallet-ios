import XCTest
import Cuckoo
@testable import Bank

class WalletManagerTests: XCTestCase {
    private var mockWordsManager: MockIWordsManager!
    private var mockCoinManager: MockICoinManager!
    private var mockAdapterFactory: MockIAdapterFactory!
    private var mockBitcoinAdapter: MockIAdapter!
    private var mockEthereumAdapter: MockIAdapter!

    private var manager: WalletManager!

    private let words = ["one", "two"]
    private let enabledCoins = ["BTC", "ETH"]

    override func setUp() {
        super.setUp()

        mockWordsManager = MockIWordsManager()
        mockCoinManager = MockICoinManager()
        mockAdapterFactory = MockIAdapterFactory()
        mockBitcoinAdapter = MockIAdapter()
        mockEthereumAdapter = MockIAdapter()

        stub(mockWordsManager) { mock in
            when(mock.words.get).thenReturn(words)
        }
        stub(mockCoinManager) { mock in
            when(mock.enabledCoins.get).thenReturn(enabledCoins)
        }
        stub(mockAdapterFactory) { mock in
            when(mock.adapter(forCoin: "BTC", words: equal(to: words))).thenReturn(mockBitcoinAdapter)
            when(mock.adapter(forCoin: "ETH", words: equal(to: words))).thenReturn(mockEthereumAdapter)
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

        manager = WalletManager(wordsManager: mockWordsManager, coinManager: mockCoinManager, adapterFactory: mockAdapterFactory)
    }

    override func tearDown() {
        mockWordsManager = nil
        mockCoinManager = nil
        mockAdapterFactory = nil
        mockBitcoinAdapter = nil
        mockEthereumAdapter = nil

        manager = nil

        super.tearDown()
    }

    func testInitWallets() {
        manager.initWallets()

        XCTAssertEqual(manager.wallets[0].coin, enabledCoins[0])
        XCTAssertEqual(manager.wallets[1].coin, enabledCoins[1])
        XCTAssertTrue(manager.wallets[0].adapter === mockBitcoinAdapter)
        XCTAssertTrue(manager.wallets[1].adapter === mockEthereumAdapter)
    }

    func testInitWallets_WithoutAdapter() {
        stub(mockAdapterFactory) { mock in
            when(mock.adapter(forCoin: "BTC", words: equal(to: words))).thenReturn(nil)
        }

        manager.initWallets()

        XCTAssertEqual(manager.wallets.count, 1)
    }

    func testInitWallets_StartAdapters() {
        manager.initWallets()

        verify(mockBitcoinAdapter).start()
        verify(mockEthereumAdapter).start()
    }

    func testInitWallets_WithoutWords() {
        stub(mockWordsManager) { mock in
            when(mock.words.get).thenReturn(nil)
        }

        manager.initWallets()

        XCTAssertEqual(manager.wallets.count, 0)
    }

    func testRefreshWallets() {
        manager.initWallets()
        manager.refreshWallets()

        verify(mockBitcoinAdapter).refresh()
        verify(mockEthereumAdapter).refresh()
    }

    func testClearWallets() {
        manager.initWallets()
        manager.clearWallets()

        verify(mockBitcoinAdapter).clear()
        verify(mockEthereumAdapter).clear()
    }

}
