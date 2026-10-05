import BigInt
import WalletConnectSign

class WCEvmWalletChainParser: IWCParser {
    private struct Params: Codable {
        let chainId: String
    }

    func parse(request: Request) throws -> WCRequestPayload? {
        guard request.chainId.namespace == WCNamespace.eip155,
              [WCEvmWalletChainPayload.switchMethod, WCEvmWalletChainPayload.addMethod].contains(request.method)
        else {
            return nil
        }

        guard let chainId = (try? request.params.get([Params].self))?.first?.chainId,
              let value = BigUInt(chainId.hasPrefix("0x") ? String(chainId.dropFirst(2)) : chainId, radix: 16),
              let targetChainId = Int(exactly: value)
        else {
            throw ParsingError.malformedParams
        }

        return WCEvmWalletChainPayload(request: request, targetChainId: targetChainId)
    }
}

extension WCEvmWalletChainParser {
    enum ParsingError: Error, Equatable {
        case malformedParams
    }
}
