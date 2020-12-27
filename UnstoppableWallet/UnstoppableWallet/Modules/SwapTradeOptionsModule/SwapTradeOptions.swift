import Foundation
import UniswapKit
import EthereumKit

struct SwapTradeOptions {
    var allowedSlippage: Decimal
    var ttl: TimeInterval
    var recipient: Address?

    init(allowedSlippage: Decimal = TradeOptions.defaultSlippage, ttl: TimeInterval = TradeOptions.defaultTtl, recipient: Address? = nil) {
        self.allowedSlippage = allowedSlippage
        self.ttl = ttl
        self.recipient = recipient
    }

    var tradeOptions: TradeOptions {
        TradeOptions(
                allowedSlippage: allowedSlippage,
                ttl: ttl,
                recipient: recipient.flatMap { try? EthereumKit.Address(hex: $0.raw) }
        )
    }

}
