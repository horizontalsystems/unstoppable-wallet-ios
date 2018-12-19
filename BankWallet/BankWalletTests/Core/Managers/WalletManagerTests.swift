import XCTest
import Cuckoo
@testable import Bank_Dev_T

class WalletManagerTests: XCTestCase {
    private var mockAdapterFactory: MockIAdapterFactory!
    private var mockBitcoinAdapter: MockIAdapter!
    private var mockEthereumAdapter: MockIAdapter!

    private var manager: WalletManager!

    private let bitcoin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
    private let ether = Coin(title: "Ethereum", code: "ETH", type: .ethereum)

    private let words = ["one", "two"]
    private var enabledCoins: [Coin]!

    override func setUp() {
        super.setUp()
        enabledCoins = [bitcoin, ether]

        mockAdapterFactory = MockIAdapterFactory()
        mockBitcoinAdapter = MockIAdapter()
        mockEthereumAdapter = MockIAdapter()

        stub(mockAdapterFactory) { mock in
            when(mock.adapter(forCoinType: equal(to: bitcoin.type), words: equal(to: words))).thenReturn(mockBitcoinAdapter)
            when(mock.adapter(forCoinType: equal(to: ether.type), words: equal(to: words))).thenReturn(mockEthereumAdapter)
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

        XCTAssertEqual(manager.wallets[0].coinCode, enabledCoins[0].code)
        XCTAssertEqual(manager.wallets[0].title, enabledCoins[0].title)
        XCTAssertEqual(manager.wallets[1].coinCode, enabledCoins[1].code)
        XCTAssertEqual(manager.wallets[1].title, enabledCoins[1].title)
        XCTAssertTrue(manager.wallets[0].adapter === mockBitcoinAdapter)
        XCTAssertTrue(manager.wallets[1].adapter === mockEthereumAdapter)
    }

    func testInitWallets_WithoutAdapter() {
        stub(mockAdapterFactory) { mock in
            when(mock.adapter(forCoinType: equal(to: bitcoin.type), words: equal(to: words))).thenReturn(nil)
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
            when(mock.adapter(forCoinType: equal(to: bitcoin.type), words: equal(to: [String]()))).thenReturn(nil)
            when(mock.adapter(forCoinType: equal(to: ether.type), words: equal(to: [String]()))).thenReturn(nil)
        }

        manager.initWallets(words: [], coins: enabledCoins)

        XCTAssertEqual(manager.wallets.count, 0)
    }

    func testClearWallets() {
        manager.initWallets(words: words, coins: enabledCoins)
        manager.clearWallets()

        verify(mockBitcoinAdapter).clear()
        verify(mockEthereumAdapter).clear()
        XCTAssertEqual(manager.wallets.count, 0)
    }

}
