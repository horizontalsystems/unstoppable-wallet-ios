import WalletConnectSign

// nil = not this parser's method; throw = this parser's method, but params are malformed
protocol IWCNParser: AnyObject {
    func parse(request: Request) throws -> WCNParsedRequest?
}

class WCNParserRegistry {
    private var parsers = [IWCNParser]()

    func register(_ parser: IWCNParser) {
        parsers.append(parser)
    }

    func parse(request: Request) throws -> WCNParsedRequest {
        for parser in parsers {
            if let parsed = try parser.parse(request: request) {
                return parsed
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
