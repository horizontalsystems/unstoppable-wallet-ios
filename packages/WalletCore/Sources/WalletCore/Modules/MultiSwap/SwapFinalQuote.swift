import Foundation
import MarketKit

public class SwapFinalQuote {
    private let expectedBuyAmount: Decimal
    private let slippage: Decimal?
    public let recipient: String?
    public let estimatedTime: TimeInterval?
    private let transactionError: Error?

    public let toAddress: String
    public private(set) var depositAddress: String?
    public private(set) var depositMemo: String?
    public let providerSwapId: String?
    public var refundAddress: String?
    public var minAmountOut: Decimal?
    // Set by the send handler from the provider; a deposit-based exchanger's estimate
    // renders as a (X−25%)–(X+25%) range instead of ~X.
    public var preciseEstimateTime = true

    public init(
        expectedBuyAmount: Decimal,
        slippage: Decimal?,
        recipient: String?,
        estimatedTime: TimeInterval? = nil,
        transactionError: Error?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil,
        refundAddress: String? = nil,
        minAmountOut: Decimal? = nil
    ) {
        self.expectedBuyAmount = expectedBuyAmount
        self.slippage = slippage
        self.recipient = recipient
        self.estimatedTime = estimatedTime
        self.transactionError = transactionError
        self.toAddress = toAddress
        self.depositAddress = depositAddress
        self.providerSwapId = providerSwapId
        self.refundAddress = refundAddress
        self.minAmountOut = minAmountOut
    }

    public var amountOut: Decimal {
        expectedBuyAmount
    }

    // Display metadata only; executable payloads retain their original address and memo.
    func setDeposit(address: String?, memo: String?) {
        depositAddress = address.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        depositMemo = memo.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
    }

    // server-enforced floor when the provider reports one, slippage estimate otherwise
    var guaranteedAmountOut: Decimal? {
        guard let slippage else {
            return nil
        }

        return minAmountOut ?? amountOut * (1 - slippage / 100)
    }

    var feeData: FeeData? {
        nil
    }

    public var canSwap: Bool {
        transactionError == nil
    }

    public func executable(tokenIn _: Token) -> ISwapExecutable {
        UnsupportedExecutable()
    }

    func feeFields(baseToken _: Token, currency _: Currency, baseTokenRate _: Decimal?) -> [SendField] {
        []
    }

    func cautions(baseToken: Token) -> [CautionNew] {
        var cautions = [CautionNew]()

        if let transactionError, let caution = caution(transactionError: transactionError, baseToken: baseToken) {
            cautions.append(caution)
        }

        return cautions
    }

    func caution(transactionError _: Error, baseToken _: Token) -> CautionNew? {
        nil
    }

    public func fields(tokenIn: Token, tokenOut: Token, baseToken _: Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate _: Decimal?) -> [SendField] {
        var fields = [SendField]()

        if let slippage {
            if let guaranteedAmountOut, let minRecieve = SendField.minRecieve(token: tokenOut, value: guaranteedAmountOut) {
                fields.append(minRecieve)
            }

            if let slippage = SendField.slippage(slippage) {
                fields.append(slippage)
            }
        }

        if let recipient {
            fields.append(.recipient(recipient, blockchainType: tokenOut.blockchainType))
        }

        if let depositAddress, !depositAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append(.recipient(title: "swap.deposit_address".localized, value: depositAddress, copyable: true, blockchainType: tokenIn.blockchainType))
        }
        if let depositMemo {
            fields.append(.hex(title: "swap.deposit_memo".localized, value: depositMemo))
        }

        // Single route on the confirm screen: no baseline, absolute threshold only.
        if let timeState = MultiSwapViewModel.timeState(for: estimatedTime, precise: preciseEstimateTime, baseline: nil) {
            fields.append(.simpleValue(
                title: ComponentInformedTitle("swap.swapped_time".localized, info: .swapTime),
                value: ComponentText(text: MultiSwapQuotesView.string(time: timeState.value), colorStyle: timeState.colorStyle)
            ))
        }

        return fields
    }
}
