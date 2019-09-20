import XCTest
import Quick
import Nimble
import Cuckoo
@testable import Bank_Dev_T

class RateListSorterTests: QuickSpec {

    override func spec() {

        let sorter = RateListSorter()
        let featuredCoins = [Coin(title: "FCoin", code: "FC", decimal: 0, type: .bitcoin),
                             Coin(title: "DCoin", code: "DC", decimal: 0, type: .bitcoin), 
                             Coin(title: "BCoin", code: "DC", decimal: 0, type: .bitcoin), 
                            ]

        describe("#smart sort") {
            it("use only non-sorted featured if coins is empty") {
                let coins = sorter.smartSort(for: [], featuredCoins: featuredCoins)
                expect(coins).to(equal(featuredCoins))
            }
            it("use non-sorted featured if coins subset of featured but in other order") {
                let userCoins = [featuredCoins[2], featuredCoins[1]]

                let coins = sorter.smartSort(for: userCoins, featuredCoins: featuredCoins)
                expect(coins).to(equal([featuredCoins[1], featuredCoins[2]]))
            }
            it("use included featured coin then sorted by COINCODE other from coins") {
                let userCoins = [Coin(title: "SUser", code: "AU", decimal: 0, type: .bitcoin),
                                     featuredCoins[1],
                                     Coin(title: "AUser", code: "ZU", decimal: 0, type: .bitcoin),
                                     Coin(title: "SUser", code: "SU", decimal: 0, type: .bitcoin),
                ]

                let coins = sorter.smartSort(for: userCoins, featuredCoins: featuredCoins)
                expect(coins).to(equal([featuredCoins[1], userCoins[0], userCoins[3], userCoins[2]]))
            }
        }
    }

}
