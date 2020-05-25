//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class FullTransactionInfoProviderFactoryTests: XCTestCase {
//
//    private var factory: FullTransactionInfoProviderFactory!
//    private var mockProviderManager: MockIFullTransactionDataProviderManager!
//    private var mockBtcProvider: MockIProvider!
//    private var mockBchProvider: MockIProvider!
//    private var mockEthProvider: MockIProvider!
//
//    private let bitcoin = Coin.mock(type: .bitcoin)
//    private let bitcoinCash = Coin.mock(type: .bitcoinCash)
//    private let ethereum = Coin.mock(type: .ethereum)
//    private let btcProvider = "btc_provider"
//    private let bchProvider = "bch_provider"
//    private let ethProvider = "eth_provider"
//
//    override func setUp() {
//        super.setUp()
//
//        mockBtcProvider = MockIProvider()
//        stub(mockBtcProvider) { mock in
//            when(mock.name.get).thenReturn(btcProvider)
//        }
//        mockBchProvider = MockIProvider()
//        stub(mockBchProvider) { mock in
//            when(mock.name.get).thenReturn(bchProvider)
//        }
//        mockEthProvider = MockIProvider()
//        stub(mockEthProvider) { mock in
//            when(mock.name.get).thenReturn(ethProvider)
//        }
//        mockProviderManager = MockIFullTransactionDataProviderManager()
//        stub(mockProviderManager) { mock in
//            when(mock.baseProvider(for: equal(to: bitcoin))).thenReturn(mockBtcProvider)
//            when(mock.baseProvider(for: equal(to: bitcoinCash))).thenReturn(mockBchProvider)
//            when(mock.baseProvider(for: equal(to: ethereum))).thenReturn(mockEthProvider)
//            when(mock.bitcoin(for: any())).thenReturn(MockIBitcoinForksProvider())
//            when(mock.bitcoinCash(for: any())).thenReturn(MockIBitcoinForksProvider())
//            when(mock.ethereum(for: any())).thenReturn(MockIEthereumForksProvider())
//        }
//
//        factory = FullTransactionInfoProviderFactory(apiProvider: MockIJsonApiProvider(), dataProviderManager: mockProviderManager)
//    }
//
//    override func tearDown() {
//        mockProviderManager = nil
//
//        mockBtcProvider = nil
//        mockBchProvider = nil
//        mockEthProvider = nil
//        factory = nil
//
//        super.tearDown()
//    }
//
//    func testBTC() {
//        _ = factory.provider(for: bitcoin)
//        verify(mockProviderManager).bitcoin(for: btcProvider)
//    }
//
//    func testBCH() {
//        _ = factory.provider(for: bitcoinCash)
//        verify(mockProviderManager).bitcoinCash(for: bchProvider)
//    }
//
//    func testETH() {
//        _ = factory.provider(for: ethereum)
//        verify(mockProviderManager).ethereum(for: ethProvider)
//    }
//
//}
