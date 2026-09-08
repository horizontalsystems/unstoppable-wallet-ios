import HsCryptoKit
import SolanaKit
import WalletConnectSign

class WCSolanaSignMessageParser: IWCParser {
    private struct Params: Codable {
        let message: String
        let pubkey: String
    }

    func parse(request: Request) throws -> WCRequestPayload? {
        guard request.chainId.namespace == WCNamespace.solana, request.method == WCSolanaSignMessagePayload.method else {
            return nil
        }

        guard let params = try? request.params.get(Params.self) else {
            throw ParsingError.malformedParams
        }
        guard (try? SolanaKit.PublicKey(params.pubkey)) != nil else {
            throw ParsingError.malformedParams
        }
        // bound the message before the O(n²) Base58 decode
        guard params.message.count <= WCSolanaLimits.maxParamsLength else {
            throw ParsingError.malformedParams
        }

        return WCSolanaSignMessagePayload(request: request, publicKey: params.pubkey, message: HsCryptoKit.Base58.decode(params.message))
    }
}

extension WCSolanaSignMessageParser {
    enum ParsingError: Error, Equatable {
        case malformedParams
    }
}
