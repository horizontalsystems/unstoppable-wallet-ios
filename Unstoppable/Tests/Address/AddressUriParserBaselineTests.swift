import Foundation
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

struct AddressUriParserBaselineTests {
    private let anyParser = AddressUriParser(blockchainType: nil, tokenType: nil)
    private let decimal = AddressUriFixtures.decimal

    @Test
    func parseNativeBitcoinUri() throws {
        let result = try anyParser.parse(url: "bitcoin:\(AddressUriFixtures.btc)?amount=0.001&label=Donation")

        #expect(result.scheme == "bitcoin")
        #expect(result.address == AddressUriFixtures.btc)
        #expect(result.parameters[.amount] == "0.001")
        #expect(result.parameters[.label] == "Donation")
        #expect(result.unhandledParameters.isEmpty)
        #expect(result.amount == .decimals(decimal("0.001")))
    }

    @Test
    func parseBitcoinWithoutQuery() throws {
        let result = try anyParser.parse(url: "bitcoin:\(AddressUriFixtures.btc)")

        #expect(result.scheme == "bitcoin")
        #expect(result.address == AddressUriFixtures.btc)
        #expect(result.parameters.isEmpty)
        #expect(result.unhandledParameters.isEmpty)
    }

    @Test
    func parseBitcoinCashKeepsSchemePrefix() throws {
        let result = try anyParser.parse(url: "\(AddressUriFixtures.bchPrefix)?amount=0.5")

        #expect(result.scheme == "bitcoincash")
        // BCH/eCash use removeScheme=false — prefix stays in the canonical address.
        #expect(result.address == AddressUriFixtures.bchPrefix)
        #expect(result.amount == .decimals(decimal("0.5")))
    }

    @Test
    func parseECashKeepsSchemePrefix() throws {
        let result = try anyParser.parse(url: "\(AddressUriFixtures.ecashPrefix)?amount=1")

        #expect(result.scheme == "ecash")
        #expect(result.address == AddressUriFixtures.ecashPrefix)
        #expect(result.amount == .decimals(Decimal(1)))
    }

    @Test
    func parseEvmWithChainId() throws {
        let result = try anyParser.parse(url: "ethereum:\(AddressUriFixtures.evmRecipient)@1?value=1000000000000000000")

        #expect(result.scheme == "ethereum")
        #expect(result.address == AddressUriFixtures.evmRecipient)
        #expect(result.parameters[.value] == "1000000000000000000")
        #expect(result.parameters[.blockchainUid] == "ethereum")
        #expect(result.amount == .points(decimal("1000000000000000000")))
    }

    @Test
    func parseEvmBscViaChainId() throws {
        let result = try anyParser.parse(url: "ethereum:\(AddressUriFixtures.evmRecipient)@56?value=10000000000000000")

        #expect(result.address == AddressUriFixtures.evmRecipient)
        #expect(result.parameters[.blockchainUid] == "binance-smart-chain")
        #expect(result.amount == .points(decimal("10000000000000000")))
    }

    @Test
    func parseEvmWithoutChainIdDoesNotSetBlockchainUid() throws {
        let result = try anyParser.parse(url: "ethereum:\(AddressUriFixtures.evmRecipient)?value=100")

        #expect(result.address == AddressUriFixtures.evmRecipient)
        #expect(result.parameters[.value] == "100")
        #expect(result.parameters[.blockchainUid] == nil)
    }

    @Test
    func parseEvmWithBrokenChainIdStripsSuffix() throws {
        let result = try anyParser.parse(url: "ethereum:\(AddressUriFixtures.evmRecipient)@xyz?value=100")

        #expect(result.address == AddressUriFixtures.evmRecipient)
        #expect(result.parameters[.value] == "100")
        #expect(result.parameters[.blockchainUid] == nil)
    }

    @Test
    func parseEvmChainIdWithoutQueryStillWritesBlockchainUid() throws {
        let result = try anyParser.parse(url: "ethereum:\(AddressUriFixtures.evmRecipient)@1")

        #expect(result.address == AddressUriFixtures.evmRecipient)
        #expect(result.parameters[.blockchainUid] == "ethereum")
        #expect(result.amount == nil)
    }

    @Test
    func parseEvmTransferUriYieldsRecipientAddress() throws {
        let result = try anyParser.parse(url: "ethereum:\(AddressUriFixtures.usdtContract)@1/transfer?address=\(AddressUriFixtures.evmRecipient)&uint256=1500000")

        #expect(result.address == AddressUriFixtures.evmRecipient)
        #expect(result.parameters[.value] == "1500000")
        #expect(result.parameters[.tokenUid] == "eip20:\(AddressUriFixtures.usdtContract)")
        #expect(result.parameters[.blockchainUid] == "ethereum")
        #expect(result.unhandledParameters.isEmpty)
    }

    @Test
    func parseTron() throws {
        let result = try anyParser.parse(url: "tron:\(AddressUriFixtures.tron)?amount=100")

        #expect(result.address == AddressUriFixtures.tron)
        #expect(result.amount == .decimals(Decimal(100)))
    }

    @Test
    func parseTonRegularUri() throws {
        let result = try anyParser.parse(url: "ton:\(AddressUriFixtures.ton)?amount=0.5")

        #expect(result.scheme == "ton")
        #expect(result.address == AddressUriFixtures.ton)
        #expect(result.amount == .decimals(decimal("0.5")))
    }

    @Test
    func parseTonDeeplinkConvertsNanograms() throws {
        let result = try anyParser.parse(url: "unstoppable.money://transfer/\(AddressUriFixtures.ton)?amount=1000000000")

        #expect(result.scheme == "ton")
        #expect(result.address == AddressUriFixtures.ton)
        // 10^9 nanograms → 1 TON via TonAdapter.amount conversion.
        #expect(result.amount == .decimals(Decimal(1)))
        #expect(result.parameters[.blockchainUid] == "the-open-network")
    }

    @Test
    func parseMonero() throws {
        let result = try anyParser.parse(url: "monero:\(AddressUriFixtures.xmrPrimary)?tx_amount=0.5&tx_description=Coffee")

        #expect(result.scheme == "monero")
        #expect(result.address == AddressUriFixtures.xmrPrimary)
        #expect(result.parameters[.txAmount] == "0.5")
        #expect(result.parameters[.txDescription] == "Coffee")
        #expect(result.amount == .decimals(decimal("0.5")))
        #expect(result.memo == "Coffee")
    }

    @Test
    func parseStellar() throws {
        let result = try anyParser.parse(url: "stellar:\(AddressUriFixtures.stellar)?amount=10&memo=Order123")

        #expect(result.scheme == "stellar")
        #expect(result.address == AddressUriFixtures.stellar)
        #expect(result.amount == .decimals(Decimal(10)))
        #expect(result.memo == "Order123")
    }

    @Test
    func parseZcash() throws {
        let result = try anyParser.parse(url: "zcash:\(AddressUriFixtures.zecShielded)?amount=0.01")

        #expect(result.scheme == "zcash")
        #expect(result.address == AddressUriFixtures.zecShielded)
        #expect(result.amount == .decimals(decimal("0.01")))
    }

    @Test
    func parseZano() throws {
        let result = try anyParser.parse(url: "zano:\(AddressUriFixtures.zano)?amount=2")

        #expect(result.address == AddressUriFixtures.zano)
        #expect(result.amount == .decimals(Decimal(2)))
    }

    @Test
    func parseLitecoin() throws {
        let result = try anyParser.parse(url: "litecoin:\(AddressUriFixtures.ltc)?amount=0.1")

        #expect(result.scheme == "litecoin")
        #expect(result.address == AddressUriFixtures.ltc)
        #expect(result.amount == .decimals(decimal("0.1")))
    }

    @Test
    func parseDash() throws {
        let result = try anyParser.parse(url: "dash:\(AddressUriFixtures.dash)?amount=5")

        #expect(result.scheme == "dash")
        #expect(result.address == AddressUriFixtures.dash)
        #expect(result.amount == .decimals(Decimal(5)))
    }

    // Solana Pay format is BIP-21-shaped; native SOL transfers parse via Bip21Parser.
    @Test
    func parseSolanaPayNative() throws {
        let result = try anyParser.parse(url: "solana:\(AddressUriFixtures.solana)?amount=5")

        #expect(result.scheme == "solana")
        #expect(result.address == AddressUriFixtures.solana)
        #expect(result.amount == .decimals(Decimal(5)))
        // allowedBlockchainTypes resolves via BlockchainType.supported.uriScheme lookup;
        // without solana.uriScheme set, send-flow would default to "all chains".
        #expect(result.allowedBlockchainTypes == [.solana])
    }

    // Builder roundtrip: receive QR for SPL must include the `solana:` scheme prefix.
    // Master-era builder dropped it (because `BlockchainType.solana.uriScheme` was nil),
    // producing schemeless QRs that downstream consumers couldn't reparse.
    @Test
    func buildSolanaSplReceiveUriIncludesScheme() throws {
        let mint = "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"
        let parser = AddressUriParser(blockchainType: .solana, tokenType: .spl(address: mint))

        var built = AddressUri(scheme: "solana")
        built.address = AddressUriFixtures.solana
        built.parameters[.amount] = "2"
        built.parameters[.blockchainUid] = "solana"
        built.parameters[.tokenUid] = "spl:\(mint)"

        let uri = parser.uri(built)
        #expect(uri.hasPrefix("solana:"))
        #expect(uri.contains(AddressUriFixtures.solana))

        let reparsed = try parser.parse(url: uri)
        #expect(reparsed.address == AddressUriFixtures.solana)
        #expect(reparsed.parameters == built.parameters)
    }

    @Test
    func gateRejectsBitcoinUriOnEthereumParser() {
        let parser = AddressUriParser(blockchainType: .ethereum, tokenType: nil)

        #expect(throws: AddressUriParser.ParseError.invalidBlockchainType) {
            try parser.parse(url: "bitcoin:\(AddressUriFixtures.btc)?amount=0.001")
        }
    }

    @Test
    func gateRejectsBlockchainUidMismatch() {
        let parser = AddressUriParser(blockchainType: .ethereum, tokenType: nil)

        #expect(throws: AddressUriParser.ParseError.invalidBlockchainType) {
            try parser.parse(url: "ethereum:\(AddressUriFixtures.evmRecipient)?value=1&blockchain_uid=binance-smart-chain")
        }
    }

    @Test
    func gateRejectsTokenUidMismatch() {
        let parser = AddressUriParser(blockchainType: .ethereum, tokenType: .native)

        #expect(throws: AddressUriParser.ParseError.invalidTokenType) {
            try parser.parse(url: "ethereum:\(AddressUriFixtures.evmRecipient)@1?value=100&token_uid=eip20:\(AddressUriFixtures.usdtContract)")
        }
    }

    @Test
    func gateRejectsInvalidTokenUid() {
        let parser = AddressUriParser(blockchainType: .ethereum, tokenType: .native)

        #expect(throws: AddressUriParser.ParseError.invalidTokenType) {
            try parser.parse(url: "ethereum:\(AddressUriFixtures.evmRecipient)@1?value=100&token_uid=garbage-uid")
        }
    }

    @Test
    func customSchemeHandlingPreservesOriginalScheme() throws {
        let result = try anyParser.parse(url: "monero:\(AddressUriFixtures.xmrPrimary)?tx_amount=0.1", customSchemeHandling: true)

        #expect(result.scheme == "monero")
        #expect(result.address == AddressUriFixtures.xmrPrimary)
        #expect(result.parameters[.txAmount] == "0.1")
    }

    @Test
    func parseGarbageNoColonThrowsNoUri() {
        #expect(throws: AddressUriParser.ParseError.noUri) {
            try anyParser.parse(url: "not a uri", customSchemeHandling: true)
        }
    }

    @Test
    func parseEmptyStringThrowsNoUri() {
        #expect(throws: AddressUriParser.ParseError.noUri) {
            try anyParser.parse(url: "")
        }
    }

    @Test
    func parseEmptyPathDoesNotThrow() throws {
        let result = try anyParser.parse(url: "bitcoin:")

        #expect(result.scheme == "bitcoin")
        #expect(result.address == "")
        #expect(result.parameters.isEmpty)
    }

    @Test
    func duplicateQueryKeysLastWriteWins() throws {
        let result = try anyParser.parse(url: "bitcoin:\(AddressUriFixtures.btc)?amount=0.1&amount=999")

        #expect(result.amount == .decimals(Decimal(999)))
    }

    @Test
    func parseEmptyQueryString() throws {
        let result = try anyParser.parse(url: "bitcoin:\(AddressUriFixtures.btc)?")

        #expect(result.scheme == "bitcoin")
        #expect(result.address == AddressUriFixtures.btc)
        #expect(result.parameters.isEmpty)
        #expect(result.unhandledParameters.isEmpty)
    }

    @Test
    func parseQueryItemWithoutValueIsSkipped() throws {
        let result = try anyParser.parse(url: "bitcoin:\(AddressUriFixtures.btc)?foo")

        #expect(result.parameters.isEmpty)
        #expect(result.unhandledParameters.isEmpty)
    }

    @Test
    func parseUrlEncodedValue() throws {
        let result = try anyParser.parse(url: "bitcoin:\(AddressUriFixtures.btc)?label=Hello%20World")

        #expect(result.parameters[.label] == "Hello World")
    }

    // Unichain (chainId 130) is not in EvmBlockchainManager.blockchainTypes; rejecting
    // here prevents the URI from silently becoming a chain-agnostic native EVM send.
    @Test
    func rejectsUnknownEvmChainIdAtParseTime() {
        #expect(throws: AddressUriParser.ParseError.invalidBlockchainType) {
            try anyParser.parse(url: "ethereum:0xCC4A9DE8B4b3F5fc8B197c8eB3B55C56D1D7aAB1@130?value=1.2e17")
        }
    }

    // `ton://transfer/...` is the tonkeeper-spec form. Two pre-existing issues pinned:
    // (a) URLComponents leaves a leading "/" in path; (b) amount is interpreted as Decimal
    // human, not nanograms (bug B1). Fix scheduled for Future F6.
    @Test
    func parseTonkeeperStyleDeeplinkPinsCurrentBugs() throws {
        let result = try anyParser.parse(url: "ton://transfer/EQBseDk7VQ8xeANJ0QS-5KEEe56SKw4-gCurRSFUVZ5wSMj9?amount=80000000000&text=4114143799")

        #expect(result.scheme == "ton")
        #expect(result.address == "/EQBseDk7VQ8xeANJ0QS-5KEEe56SKw4-gCurRSFUVZ5wSMj9")
        #expect(result.amount == .decimals(decimal("80000000000")))
        #expect(result.unhandledParameters["text"] == "4114143799")
    }

    @Test
    func parseTonOpaqueWithMemo() throws {
        let result = try anyParser.parse(url: "ton:EQBseDk7VQ8xeANJ0QS-5KEEe56SKw4-gCurRSFUVZ5wSMj9?amount=80&memo=4114143799")

        #expect(result.scheme == "ton")
        #expect(result.address == "EQBseDk7VQ8xeANJ0QS-5KEEe56SKw4-gCurRSFUVZ5wSMj9")
        #expect(result.amount == .decimals(Decimal(80)))
        #expect(result.memo == "4114143799")
    }

    @Test
    func parseEthereumValueIntegerWei() throws {
        let result = try anyParser.parse(url: "ethereum:0x7bc7FDA2EdB3a44dc5c043A078627233C41229ae?value=6000")

        #expect(result.scheme == "ethereum")
        #expect(result.address == "0x7bc7FDA2EdB3a44dc5c043A078627233C41229ae")
        #expect(result.parameters[.value] == "6000")
        #expect(result.parameters[.blockchainUid] == nil)
        #expect(result.amount == .points(Decimal(6000)))
    }

    @Test
    func parseEthereumValueScientificNotation() throws {
        let result = try anyParser.parse(url: "ethereum:0x7bc7FDA2EdB3a44dc5c043A078627233C41229ae?value=2e17")

        #expect(result.parameters[.value] == "2e17")
        #expect(result.amount == .points(decimal("2e17")))
    }

    @Test
    func parseEthereumFractionalValueAndOurCustomFields() throws {
        let result = try anyParser.parse(url: "ethereum:0xbD33256E3C917951969ECCDB174615a6c825DdA1?blockchain_uid=ethereum&token_uid=native&value=0.6")

        #expect(result.address == "0xbD33256E3C917951969ECCDB174615a6c825DdA1")
        #expect(result.parameters[.blockchainUid] == "ethereum")
        #expect(result.parameters[.tokenUid] == "native")
        #expect(result.parameters[.value] == "0.6")
        #expect(result.amount == .points(decimal("0.6")))
    }
}
