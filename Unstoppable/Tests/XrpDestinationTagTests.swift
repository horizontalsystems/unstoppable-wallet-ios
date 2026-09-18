import Testing
@testable import WalletCore

// The XRP deposit identifier (Android `XrpDestinationTagTest`). Every case here is a way to lose
// a deposit: a tag dropped, or a tag truncated into somebody else's order.
struct XrpDestinationTagTests {
    @Test func wholeNumberWithinTheFieldIsATag() {
        #expect(XrpDestinationTag.parse("0") == 0)
        #expect(XrpDestinationTag.parse("123456") == 123_456)
        #expect(XrpDestinationTag.parse("4294967295") == XrpDestinationTag.max)
    }

    @Test func surroundingWhitespaceIsTrimmed() {
        #expect(XrpDestinationTag.parse(" 123456 ") == 123_456)
        #expect(XrpDestinationTag.parse("\n42\t") == 42)
    }

    @Test func anythingTheFieldCannotHoldIsNotATag() {
        #expect(XrpDestinationTag.parse("4294967296") == nil)
        #expect(XrpDestinationTag.parse("-1") == nil)
        #expect(XrpDestinationTag.parse("1.5") == nil)
        #expect(XrpDestinationTag.parse("1e3") == nil)
        #expect(XrpDestinationTag.parse("1,234") == nil)
        #expect(XrpDestinationTag.parse("0x10") == nil)
        #expect(XrpDestinationTag.parse("abc") == nil)
    }

    @Test func emptyInputIsNotATag() {
        #expect(XrpDestinationTag.parse("") == nil)
        #expect(XrpDestinationTag.parse("   ") == nil)
    }

    // Digits the ledger cannot hold either: the field is decimal, not any numeric script
    @Test func nonAsciiDigitsAreNotATag() {
        #expect(XrpDestinationTag.parse("１２３") == nil)
        #expect(XrpDestinationTag.parse("٤٢") == nil)
    }
}
