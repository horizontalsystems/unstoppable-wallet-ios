import MarketKit

// Stellar-native DEX routes (server-built XDR). These providers publish no token list, so assets are
// encoded directly: native XLM → `XLM.XLM`, classic asset → `XLM.<CODE>-<ISSUER>` with the code
// verbatim (case-sensitive). Soroban-only contract tokens (`C…`) are not supported by the server.
public final class StellarUSwapSubProvider: DefaultUSwapSubProvider {
    override public func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        tokenIn.blockchainType == .stellar
            && tokenOut.blockchainType == .stellar
            && super.supports(tokenIn: tokenIn, tokenOut: tokenOut)
    }

    override func asset(token: Token) -> String? {
        guard token.blockchainType == .stellar else {
            return nil
        }

        switch token.type {
        case .native:
            return "XLM.XLM"
        case let .stellar(code, issuer):
            // classic assets are issued by a `G…` account; anything else is not a classic asset
            guard issuer.hasPrefix("G") else {
                return nil
            }
            return "XLM.\(code)-\(issuer)"
        default:
            return nil
        }
    }
}
