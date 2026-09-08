import BigInt
import WalletConnectSign

class WCNEvmWalletChainParser: IWCNParser {
    private struct Params: Codable {
        let chainId: String
    }

    func parse(request: Request) throws -> WCNRequestPayload? {
        guard request.chainId.namespace == WCNNamespace.eip155,
              [WCNEvmWalletChainPayload.switchMethod, WCNEvmWalletChainPayload.addMethod].contains(request.method)
        else {
            return nil
        }

        guard let chainId = (try? request.params.get([Params].self))?.first?.chainId,
              let value = BigUInt(chainId.hasPrefix("0x") ? String(chainId.dropFirst(2)) : chainId, radix: 16),
              let targetChainId = Int(exactly: value)
        else {
            throw ParsingError.malformedParams
        }

        return WCNEvmWalletChainPayload(request: request, targetChainId: targetChainId)
    }
}

extension WCNEvmWalletChainParser {
    enum ParsingError: Error, Equatable {
        case malformedParams
    }
}
