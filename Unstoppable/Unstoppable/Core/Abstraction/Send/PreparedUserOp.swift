import Foundation
import MarketKit

struct PreparedUserOp {
    let userOp: UserOperation
    let userOpHash: Data
    let isFreshDeployment: Bool
    let gasEstimate: PimlicoProvider.GasEstimate
    let gasPrices: PimlicoProvider.GasPrices.Tier
    let paymasterMode: PimlicoProvider.PaymasterMode
    let baseToken: Token
    let curve: SignatureCurve
    let decoration: EvmDecoration
    let feeBreakdown: AaSendFeeBreakdown
}
