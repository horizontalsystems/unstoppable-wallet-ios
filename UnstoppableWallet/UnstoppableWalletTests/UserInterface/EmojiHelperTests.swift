//import XCTest
//import Quick
//import Nimble
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class EmojiHelperTests: QuickSpec {
//
//    override func spec() {
//
//        let helper = EmojiHelper()
//        let emojiBodyArray = ["", "😎", "😉", "🙂", "", "😩", "😧", "😔"]
//        let states: [Int] = [0, 5, 3, 2]
//        let emojiTitleArray = ["💔", "💔", "💔", "💔", "💔", "🚀", "🚀", "🚀🌙", "🚀🌙"]
//        let titleStates: [Int] = [-7, -5, -3, -2, 0, 2, 3, 5, 6]
//
//        describe("#body") {
//            it("loop all states") {
//                for (index, state) in states.enumerated() {
//                    let positiveEmoji = helper.body(forState: state)
//                    expect(positiveEmoji).to(equal(emojiBodyArray[index]))
//                    let negativeEmoji = helper.body(forState: -state)
//                    expect(negativeEmoji).to(equal(emojiBodyArray[index + 4]))
//                }
//            }
//        }
//
//        describe("#title") {
//            it("loop all states") {
//                for (index, state) in titleStates.enumerated() {
//                    let emoji = helper.title(forState: state)
//                    expect(emoji).to(equal(emojiTitleArray[index]))
//                }
//            }
//        }
//
//        describe("#title") {
//            it("check multi alerts emoji") {
//                expect(helper.multiAlerts).to(equal("📉📈"))
//            }
//        }
//    }
//
//}
