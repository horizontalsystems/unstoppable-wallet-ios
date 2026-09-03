import WalletConnectSign

// nil = not this parser's method; throw = this parser's method, but params are malformed
protocol IWCNParser: AnyObject {
    func parse(request: Request) throws -> WCNRequestPayload?
}

class WCNParserRegistry {
    private var parsers = [IWCNParser]()

    func register(_ parser: IWCNParser) {
        parsers.append(parser)
    }

    func parse(request: Request) throws -> WCNRequestPayload {
        for parser in parsers {
            if let payload = try parser.parse(request: request) {
                return payload
            }
        }

        throw ParsingError.unsupportedMethod(request.method)
    }
}

extension WCNParserRegistry {
    enum ParsingError: Error, Equatable {
        case unsupportedMethod(String)
    }
}
