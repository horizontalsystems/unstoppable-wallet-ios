import Foundation
import MarketKit

class MultiSwapHelpers {
    static func estimate(tokenIn: Token, tokenOut: Token) -> TimeInterval? {
        if tokenIn.blockchainType == tokenOut.blockchainType {
            return tokenIn.blockchainType.blockTime
        }

        let crossTime: TimeInterval = (tokenIn.blockchainType.blockTime ?? 0) + (tokenOut.blockchainType.blockTime ?? 0)
        return (crossTime > 0) ? crossTime : nil
    }
}
