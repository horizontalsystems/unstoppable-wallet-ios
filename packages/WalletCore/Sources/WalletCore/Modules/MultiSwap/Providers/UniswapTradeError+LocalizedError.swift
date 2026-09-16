import Foundation
import UniswapKit

extension UniswapKit.Kit.TradeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .tradeNotFound: return "swap.trade_error.not_found".localized
        default: return nil
        }
    }
}

extension UniswapKit.KitV3.TradeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .tradeNotFound: return "swap.trade_error.not_found".localized
        default: return nil
        }
    }
}
