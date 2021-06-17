import Foundation
import UniswapKit
import EthereumKit

struct OneInchSettings {
    var allowedSlippage: Decimal
    var gasPrice: Decimal
    var recipient: Address?

    init(allowedSlippage: Decimal = 0.5, gasPrice: Decimal = 15, recipient: Address? = nil) {
        self.allowedSlippage = allowedSlippage
        self.gasPrice = gasPrice
        self.recipient = recipient
    }

    var tradeOptions: Decimal {
        10
//        TradeOptions(
//                allowedSlippage: allowedSlippage,
//                ttl: ttl,
//                recipient: recipient.flatMap { try? EthereumKit.Address(hex: $0.raw) }
//        )
    }

}
