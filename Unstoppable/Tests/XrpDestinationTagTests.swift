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

// Resolving the swap route's attachment into the tag (Android `XrpDestinationTagTest`, the
// resolution half). Each failure here is a deposit the provider could not match.
struct XrpSwapAttachmentTests {
    private func resolve(_ attachment: USwapMultiSwapApi.Attachment?) throws -> UInt32? {
        try USwapMultiSwapApi.Attachment.destinationTag(attachment)
    }

    @Test func numericDestinationTagResolves() throws {
        #expect(try resolve(.destinationTag("99")) == 99)
        #expect(try resolve(.destinationTag("0")) == 0)
        #expect(try resolve(.destinationTag("4294967295")) == XrpDestinationTag.max)
    }

    @Test func noAttachmentMeansCreditedByAddressAlone() throws {
        #expect(try resolve(nil) == nil)
    }

    // A text attachment would have to ride an XRPL memo, which providers do not read
    @Test func textAttachmentFailsTheRoute() {
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.unsupported) { try resolve(.text("order-42")) }
    }

    @Test func unknownAttachmentFailsTheRoute() {
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.unsupported) { try resolve(.unknown(type: "note", value: "x")) }
    }

    // Truncating it would credit somebody else's order
    @Test func tagTheFieldCannotHoldFailsTheRoute() {
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.outOfRange) { try resolve(.destinationTag("4294967296")) }
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.outOfRange) { try resolve(.destinationTag("-1")) }
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.outOfRange) { try resolve(.destinationTag("abc")) }
    }
}
