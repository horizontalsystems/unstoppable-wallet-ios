//import XCTest
//import Quick
//import Nimble
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class RateListSorterTests: QuickSpec {
//
//    override func spec() {
//
//        let sorter = RateListSorter()
//        let featuredCoins = [Coin.mock(title: "FCoin", code: "FC"),
//                             Coin.mock(title: "DCoin", code: "DC"),
//                             Coin.mock(title: "BCoin", code: "DC"),
//                            ]
//
//        describe("#smart sort") {
//            it("use only non-sorted featured if coins is empty") {
//                let coins = sorter.smartSort(for: [], featuredCoins: featuredCoins)
//                expect(coins).to(equal(featuredCoins))
//            }
//            it("use non-sorted featured if coins subset of featured but in other order") {
//                let userCoins = [featuredCoins[2], featuredCoins[1]]
//
//                let coins = sorter.smartSort(for: userCoins, featuredCoins: featuredCoins)
//                expect(coins).to(equal([featuredCoins[1], featuredCoins[2]]))
//            }
//            it("use included featured coin then sorted by COINCODE other from coins") {
//                let userCoins = [
//                    Coin.mock(title: "SUser", code: "AU"),
//                    featuredCoins[1],
//                    Coin.mock(title: "AUser", code: "ZU"),
//                    Coin.mock(title: "SUser", code: "SU"),
//                ]
//
//                let coins = sorter.smartSort(for: userCoins, featuredCoins: featuredCoins)
//                expect(coins).to(equal([featuredCoins[1], userCoins[0], userCoins[3], userCoins[2]]))
//            }
//        }
//    }
//
//}
