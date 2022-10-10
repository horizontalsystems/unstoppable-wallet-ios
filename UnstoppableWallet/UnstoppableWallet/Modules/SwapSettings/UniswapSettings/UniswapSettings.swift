import Foundation
import UniswapKit
import EvmKit

struct UniswapSettings {
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
                recipient: recipient.flatMap { try? EvmKit.Address(hex: $0.raw) }
        )
    }

}
