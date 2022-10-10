import Foundation
import UniswapKit
import EvmKit

struct OneInchSettings {
    var allowedSlippage: Decimal
    var recipient: Address?

    init(allowedSlippage: Decimal = 1, recipient: Address? = nil) {
        self.allowedSlippage = allowedSlippage
        self.recipient = recipient
    }

}
