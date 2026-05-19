import BigInt
import EvmKit
import Foundation
import MarketKit

// EIP-681 ERC-20 `transfer(address,uint256)` strict-gate parser.
// Anything other than a well-formed `transfer` call throws — silent fallback into a "native
// send to contract address" interpretation would let a crafted URI phish the user into
// approving a token transfer that looks like a plain ETH transfer.
enum Erc681PaymentParser {
    // Swift Decimal holds ≤ 38 significant digits; larger values silently lose precision.
    private static let decimalPrecisionLimit: BigUInt = {
        var n: BigUInt = 1
        for _ in 0 ..< 38 {
            n *= 10
        }
        return n
    }()

    private static let uint256Max: BigUInt = (BigUInt(1) << 256) - 1

    private static let addressParam = "address"
    private static let uint256Param = "uint256"

    struct Erc20Transfer {
        let blockchainType: BlockchainType?
        let recipient: String
        let contract: String
        let value: String
    }

    static func parse(parts: Eip681PathParts, queryItems: [URLQueryItem], hasValueParameter: Bool) throws -> Erc20Transfer? {
        guard let function = parts.function else { return nil }
        guard function == "transfer" else { throw AddressUriParser.ParseError.wrongUri }
        guard (try? EvmKit.Address(hex: parts.address)) != nil else { throw AddressUriParser.ParseError.wrongUri }
        guard !hasValueParameter else { throw AddressUriParser.ParseError.wrongUri }

        let recipient = try extractRecipient(queryItems: queryItems)
        let value = try extractAmount(queryItems: queryItems)
        return Erc20Transfer(
            blockchainType: parts.blockchainType,
            recipient: recipient,
            contract: parts.address,
            value: value
        )
    }

    private static func extractRecipient(queryItems: [URLQueryItem]) throws -> String {
        let matches = queryItems.filter { $0.name == addressParam }
        guard matches.count == 1, let raw = matches[0].value, (try? EvmKit.Address(hex: raw)) != nil else {
            throw AddressUriParser.ParseError.wrongUri
        }
        return raw
    }

    private static func extractAmount(queryItems: [URLQueryItem]) throws -> String {
        let matches = queryItems.filter { $0.name == uint256Param }
        guard matches.count == 1, let raw = matches[0].value, !raw.isEmpty,
              let bigAmount = BigUInt(raw, radix: 10),
              bigAmount <= uint256Max,
              bigAmount < decimalPrecisionLimit,
              Decimal(string: raw) != nil
        else {
            throw AddressUriParser.ParseError.wrongUri
        }
        return raw
    }
}
