import XCTest
import Quick
import Nimble
import Cuckoo
@testable import Bank_Dev_T

class CreateWalletViewItemFactoryTests: QuickSpec {

    override func spec() {
        let factory = CreateWalletViewItemFactory()

        describe("#viewItems") {

            describe("title") {
                let titleBtc = "Bitcoin"
                let titleEth = "Ethereum"
                let coinBtc = Coin.mock(title: titleBtc)
                let coinEth = Coin.mock(title: titleEth)

                it("sets title from coin") {
                    let viewItems = factory.viewItems(coins: [coinBtc, coinEth], selectedIndex: 0)
                    expect(viewItems[0].title).to(equal(titleBtc))
                    expect(viewItems[1].title).to(equal(titleEth))
                }
            }

            describe("code") {
                let codeBtc = "BTC"
                let codeEth = "ETH"
                let coinBtc = Coin.mock(code: codeBtc)
                let coinEth = Coin.mock(code: codeEth)

                it("sets code from coin") {
                    let viewItems = factory.viewItems(coins: [coinBtc, coinEth], selectedIndex: 0)
                    expect(viewItems[0].code).to(equal(codeBtc))
                    expect(viewItems[1].code).to(equal(codeEth))
                }
            }

            describe("selected") {
                let selectedIndex = 1
                let coins = [Coin.mock(), Coin.mock(), Coin.mock()]

                it("sets correct selected flag") {
                    let viewItems = factory.viewItems(coins: coins, selectedIndex: selectedIndex)
                    expect(viewItems[0].selected).to(beFalse())
                    expect(viewItems[1].selected).to(beTrue())
                    expect(viewItems[2].selected).to(beFalse())
                }
            }
        }
    }
}
