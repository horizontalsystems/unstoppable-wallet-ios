import WalletConnectSign

// nil = not this parser's method; throw = this parser's method, but params are malformed
protocol IWCParser: AnyObject {
    func parse(request: Request) throws -> WCRequestPayload?
}

class WCParserRegistry {
    private var parsers = [IWCParser]()

    func register(_ parser: IWCParser) {
        parsers.append(parser)
    }

    func parse(request: Request) throws -> WCRequestPayload {
        for parser in parsers {
            if let payload = try parser.parse(request: request) {
                return payload
            }
        }

        throw ParsingError.unsupportedMethod(request.method)
    }
}

extension WCParserRegistry {
    enum ParsingError: Error, Equatable {
        case unsupportedMethod(String)
    }
}
