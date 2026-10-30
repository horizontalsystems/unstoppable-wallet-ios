import Foundation
import Testing
@testable import WalletCore

struct MnemonicWordReplacementTests {
    @Test func replacesMiddleWordAndAppendsSpace() throws {
        let result = try #require(RestoreMnemonicViewModel.replacingWord(in: "abandon abil zoo", range: NSRange(location: 8, length: 4), with: "ability"))

        #expect(result.text == "abandon ability  zoo")
        #expect(result.caretOffset == 16)
    }

    @Test func replacesLastPartialWordAndAppendsSpace() throws {
        let result = try #require(RestoreMnemonicViewModel.replacingWord(in: "abandon abil", range: NSRange(location: 8, length: 4), with: "ability"))

        #expect(result.text == "abandon ability ")
        #expect(result.caretOffset == 16)
    }

    @Test func replacesCompleteWordUnderCaret() throws {
        let result = try #require(RestoreMnemonicViewModel.replacingWord(in: "zoo", range: NSRange(location: 0, length: 3), with: "zoo"))

        #expect(result.text == "zoo ")
        #expect(result.caretOffset == 4)
    }

    @Test func outOfBoundsRangeReturnsNil() {
        let result = RestoreMnemonicViewModel.replacingWord(in: "abandon", range: NSRange(location: 10, length: 4), with: "ability")

        #expect(result == nil)
    }

    @Test func nonBmpPrefixKeepsUtf16Units() throws {
        let result = try #require(RestoreMnemonicViewModel.replacingWord(in: "😀 abil", range: NSRange(location: 3, length: 4), with: "ability"))

        #expect(result.text == "😀 ability ")
        #expect(result.caretOffset == 11)
        #expect((result.text as NSString).length == 11)
    }

    @Test func japaneseWordKeepsUtf16Units() throws {
        let result = try #require(RestoreMnemonicViewModel.replacingWord(in: "あい", range: NSRange(location: 0, length: 2), with: "あいこくしん"))

        #expect(result.text == "あいこくしん ")
        #expect(result.caretOffset == 7)
    }
}
