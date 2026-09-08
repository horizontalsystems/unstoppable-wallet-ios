import HsCryptoKit
import SolanaKit
import WalletConnectSign

class WCNSolanaSignMessageParser: IWCNParser {
    private struct Params: Codable {
        let message: String
        let pubkey: String
    }

    func parse(request: Request) throws -> WCNRequestPayload? {
        guard request.chainId.namespace == WCNNamespace.solana, request.method == WCNSolanaSignMessagePayload.method else {
            return nil
        }

        guard let params = try? request.params.get(Params.self) else {
            throw ParsingError.malformedParams
        }
        guard (try? SolanaKit.PublicKey(params.pubkey)) != nil else {
            throw ParsingError.malformedParams
        }
        // bound the message before the O(n²) Base58 decode
        guard params.message.count <= WCNSolanaLimits.maxParamsLength else {
            throw ParsingError.malformedParams
        }

        return WCNSolanaSignMessagePayload(request: request, publicKey: params.pubkey, message: HsCryptoKit.Base58.decode(params.message))
    }
}

extension WCNSolanaSignMessageParser {
    enum ParsingError: Error, Equatable {
        case malformedParams
    }
}
