import XCTest
import Cuckoo
@testable import Bank_Dev_T

class ManageCoinsPresenterStateTests: XCTestCase {
    private var bitcoin: Coin!
    private var bitcoinCash: Coin!
    private var ethereum: Coin!

    private var state: ManageCoinsPresenterState!

    private var allCoins: [Coin]!
    private var enabledCoins: [Coin]!
    private var disabledCoins: [Coin]!

    override func setUp() {
        super.setUp()
        bitcoin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
        bitcoinCash = Coin(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash)
        ethereum = Coin(title: "Ethereum", code: "ETH", type: .ethereum)
        allCoins = [
            bitcoin,
            bitcoinCash,
            ethereum
        ]
        enabledCoins = [
            bitcoin,
            ethereum
        ]
        disabledCoins = [
            bitcoinCash,
        ]


        state = ManageCoinsPresenterState()
    }

    override func tearDown() {
        state = nil

        super.tearDown()
    }

    func testAdd() {
        state.allCoins = allCoins
        state.enabledCoins = enabledCoins

        state.add(coin: bitcoinCash)
        XCTAssertEqual(state.enabledCoins, [bitcoin, ethereum, bitcoinCash])
    }

    func testRemove() {
        state.allCoins = allCoins
        state.enabledCoins = enabledCoins

        state.remove(coin: bitcoin)
        XCTAssertEqual(state.enabledCoins, [ethereum])
    }

    func testMove() {
        state.allCoins = allCoins
        state.enabledCoins = enabledCoins

        state.move(coin: ethereum, to: 0)
        XCTAssertEqual(state.enabledCoins, [ethereum, bitcoin])
    }

    func testDisabledCoins() {
        state.allCoins = allCoins
        state.enabledCoins = enabledCoins

        XCTAssertEqual(state.disabledCoins, [bitcoinCash])
    }

}
