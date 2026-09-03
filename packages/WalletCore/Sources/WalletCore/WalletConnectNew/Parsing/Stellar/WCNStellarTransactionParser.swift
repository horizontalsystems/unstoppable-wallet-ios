import stellarsdk
import WalletConnectSign

class WCNStellarTransactionParser: IWCNParser {
    func parse(request: Request) throws -> WCNParsedRequest? {
        guard request.chainId.namespace == WCNNamespace.stellar,
              [WCNStellarTransactionParsed.signMethod, WCNStellarTransactionParsed.submitMethod].contains(request.method)
        else {
            return nil
        }

        guard let xdr = (try? request.params.get([String: String].self))?["xdr"] else {
            throw ParsingError.malformedParams
        }

        guard let transaction = try? Transaction(envelopeXdr: xdr) else {
            throw ParsingError.invalidEnvelope
        }

        return WCNStellarTransactionParsed(request: request, xdr: xdr, sourceAccountId: transaction.sourceAccount.keyPair.accountId)
    }
}

extension WCNStellarTransactionParser {
    enum ParsingError: Error, Equatable {
        case malformedParams
        case invalidEnvelope
    }
}
