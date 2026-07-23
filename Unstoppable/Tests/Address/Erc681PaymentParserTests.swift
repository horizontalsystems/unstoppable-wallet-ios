import Foundation
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

struct Erc681PaymentParserTests {
    private let anyParser = AddressUriParser(blockchainType: nil, tokenType: nil)

    @Test
    func parsesTransferUri() throws {
        let result = try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/transfer?address=\(AddressUriFixtures.evmRecipient)&uint256=1500000")

        #expect(result.scheme == "ethereum")
        #expect(result.address == AddressUriFixtures.evmRecipient)
        #expect(result.parameters[.blockchainUid] == "ethereum")
        #expect(result.parameters[.tokenUid] == "eip20:\(AddressUriFixtures.usdtContract)")
        #expect(result.parameters[.value] == "1500000")
        #expect(result.unhandledParameters.isEmpty)
    }

    @Test
    func parsesPayPrefixedTransferUri() throws {
        let result = try anyParser.parse(url: "ethereum:pay-\(AddressUriFixtures.usdtContract)@1/transfer?address=\(AddressUriFixtures.evmRecipient)&uint256=1500000")

        #expect(result.address == AddressUriFixtures.evmRecipient)
        #expect(result.parameters[.tokenUid] == "eip20:\(AddressUriFixtures.usdtContract)")
        #expect(result.parameters[.value] == "1500000")
    }

    @Test
    func rejectsApprove() {
        #expect(throws: AddressUriParser.ParseError.wrongUri) {
            try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/approve?address=\(AddressUriFixtures.evmRecipient)&uint256=1000000")
        }
    }

    // EIP-681: @chain_id is optional. Per spec the client uses its "current network setting";
    // for our multi-chain wallet we leave blockchain_uid unset — the eip20:<contract> tokenUid
    // pins to a chain-specific contract (USDT at 0xdAC17… only exists on mainnet).
    @Test
    func parsesTransferWithoutChainIdAsAmbiguousChain() throws {
        let result = try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)/transfer?address=\(AddressUriFixtures.evmRecipient)&uint256=1000000")

        #expect(result.scheme == "ethereum")
        #expect(result.address == AddressUriFixtures.evmRecipient)
        #expect(result.parameters[.blockchainUid] == nil)
        #expect(result.parameters[.tokenUid] == "eip20:\(AddressUriFixtures.usdtContract)")
        #expect(result.parameters[.value] == "1000000")
    }

    @Test
    func rejectsTransferWithSimultaneousValue() {
        #expect(throws: AddressUriParser.ParseError.wrongUri) {
            try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/transfer?address=\(AddressUriFixtures.evmRecipient)&uint256=1000000&value=100")
        }
    }

    @Test
    func rejectsBrokenEip55Checksum() {
        // Bit-flipped EIP-55 case relative to evmRecipient.
        let brokenChecksum = "0xA24c159C7F1E4A04dab7c364C2A8b87b3dBa4cd1"

        #expect(throws: AddressUriParser.ParseError.wrongUri) {
            try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/transfer?address=\(brokenChecksum)&uint256=1")
        }
    }

    @Test
    func rejectsDuplicateAddressParam() {
        let lowerRecipient = AddressUriFixtures.evmRecipient.lowercased()

        #expect(throws: AddressUriParser.ParseError.wrongUri) {
            try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/transfer?address=\(AddressUriFixtures.evmRecipient)&address=\(lowerRecipient)&uint256=1")
        }
    }

    @Test
    func rejectsUint256ExceedingDecimalPrecisionCap() {
        let tooBig = String(repeating: "9", count: 39)

        #expect(throws: AddressUriParser.ParseError.wrongUri) {
            try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/transfer?address=\(AddressUriFixtures.evmRecipient)&uint256=\(tooBig)")
        }
    }

    @Test
    func rejectsNegativeUint256() {
        #expect(throws: AddressUriParser.ParseError.wrongUri) {
            try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/transfer?address=\(AddressUriFixtures.evmRecipient)&uint256=-1")
        }
    }

    @Test
    func rejectsEmptyUint256() {
        #expect(throws: AddressUriParser.ParseError.wrongUri) {
            try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/transfer?address=\(AddressUriFixtures.evmRecipient)&uint256=")
        }
    }

    @Test
    func rejectsTransferWithoutQuery() {
        #expect(throws: AddressUriParser.ParseError.wrongUri) {
            try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/transfer")
        }
    }
}
