import stellarsdk
import WalletConnectSign

class WCStellarTransactionParser: IWCParser {
    func parse(request: Request) throws -> WCRequestPayload? {
        guard request.chainId.namespace == WCNamespace.stellar,
              [WCStellarTransactionPayload.signMethod, WCStellarTransactionPayload.submitMethod].contains(request.method)
        else {
            return nil
        }

        guard let xdr = (try? request.params.get([String: String].self))?["xdr"] else {
            throw ParsingError.malformedParams
        }

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
