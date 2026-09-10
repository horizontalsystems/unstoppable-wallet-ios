import stellarsdk
import WalletConnectSign

class WCStellarTransactionParser: IWCParser {
    private struct Params: Codable {
        let xdr: String
    }

    func parse(request: Request) throws -> WCRequestPayload? {
        guard request.chainId.namespace == WCNamespace.stellar,
              [WCStellarTransactionPayload.signMethod, WCStellarTransactionPayload.submitMethod].contains(request.method)
        else {
            return nil
        }

        guard let params = try? request.params.get(Params.self) else {
            throw ParsingError.malformedParams
        }

        let xdr = params.xdr
        guard let transaction = try? Transaction(envelopeXdr: xdr) else {
            throw ParsingError.invalidEnvelope
        }

        return WCStellarTransactionPayload(request: request, xdr: xdr, sourceAccountId: transaction.sourceAccount.keyPair.accountId)
    }
}

extension WCStellarTransactionParser {
    enum ParsingError: Error, Equatable {
        case malformedParams
        case invalidEnvelope
    }
}
