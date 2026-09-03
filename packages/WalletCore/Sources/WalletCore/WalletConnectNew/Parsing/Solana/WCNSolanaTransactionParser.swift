import Foundation
import SolanaKit
import WalletConnectSign

class WCNSolanaTransactionParser: IWCNParser {
    private struct Params: Codable {
        let transaction: String?
        let transactions: [String]?
    }

    private let accountProvider: ICurrentAddressProvider

    init(accountProvider: ICurrentAddressProvider) {
        self.accountProvider = accountProvider
    }

    func parse(request: Request) throws -> WCNParsedRequest? {
        guard request.chainId.namespace == WCNNamespace.solana,
              [WCNSolanaTransactionParsed.signMethod, WCNSolanaTransactionParsed.signAllMethod, WCNSolanaTransactionParsed.signAndSendMethod].contains(request.method)
        else {
            return nil
        }

        let params = try? request.params.get(Params.self)
        let encoded = request.method == WCNSolanaTransactionParsed.signAllMethod ? params?.transactions : params?.transaction.map { [$0] }

        guard let encoded, !encoded.isEmpty else {
            throw ParsingError.malformedParams
        }

        let rawTransactions = try encoded.map { base64 in
            guard let data = Data(base64Encoded: base64) else {
                throw ParsingError.malformedParams
            }
            return data
        }

        let requiredSigners = try rawTransactions.map { raw in
            guard let signers = try? SolanaKit.Kit.requiredSigners(rawTransaction: raw) else {
                throw ParsingError.invalidTransaction
            }
            return signers
        }

        // our account is the signer only when every transaction in the batch requires it
        let address = accountProvider.address
        let from = address.flatMap { address in requiredSigners.allSatisfy { $0.contains(address) } ? address : nil }

        return WCNSolanaTransactionParsed(request: request, rawTransactions: rawTransactions, requiredSigners: requiredSigners, from: from)
    }
}

extension WCNSolanaTransactionParser {
    enum ParsingError: Error, Equatable {
        case malformedParams
        case invalidTransaction
    }
}
