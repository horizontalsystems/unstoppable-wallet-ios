//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class ManageWalletsPresenterStateTests: XCTestCase {
//    private var bitcoin: Coin!
//    private var bitcoinCash: Coin!
//    private var ethereum: Coin!
//
//    private var state: ManageWalletsPresenterState!
//
//    private var allCoins: [Coin]!
//    private var enabledCoins: [Coin]!
//    private var disabledCoins: [Coin]!
//
//    override func setUp() {
//        super.setUp()
//        bitcoin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
//        bitcoinCash = Coin(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash)
//        ethereum = Coin(title: "Ethereum", code: "ETH", type: .ethereum)
//        allCoins = [
//            bitcoin,
//            bitcoinCash,
//            ethereum
//        ]
//        enabledCoins = [
//            bitcoin,
//            ethereum
//        ]
//        disabledCoins = [
//            bitcoinCash,
//        ]
//
//
//        state = ManageWalletsPresenterState()
//    }
//
//    override func tearDown() {
//        state = nil
//
//        super.tearDown()
//    }
//
//    func testEnable() {
//        state.allCoins = allCoins
//        state.wallets = enabledCoins
//
//        state.enable(coin: bitcoinCash)
//        XCTAssertEqual(state.wallets, [bitcoin, ethereum, bitcoinCash])
//    }
//
//    func testDisable() {
//        state.allCoins = allCoins
//        state.wallets = enabledCoins
//
//        state.disable(coin: bitcoin)
//        XCTAssertEqual(state.wallets, [ethereum])
//    }
//
//    func testMove() {
//        state.allCoins = allCoins
//        state.wallets = enabledCoins
//
//        state.move(coin: ethereum, to: 0)
//        XCTAssertEqual(state.wallets, [ethereum, bitcoin])
//    }
//
//    func testDisabledCoins() {
//        state.allCoins = allCoins
//        state.wallets = enabledCoins
//
//        XCTAssertEqual(state.coins, [bitcoinCash])
//    }
//
//}
