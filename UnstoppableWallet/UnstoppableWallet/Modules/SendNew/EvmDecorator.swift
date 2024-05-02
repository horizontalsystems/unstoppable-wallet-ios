import Eip20Kit
import EvmKit
import MarketKit

struct EvmDecorator {
    private let coinManager = App.shared.coinManager
    private let evmLabelManager = App.shared.evmLabelManager

    func decorate(baseToken: Token, transactionData: TransactionData, transactionDecoration: TransactionDecoration?) -> EvmDecoration {
        var type: EvmDecoration.`Type`?
        var customSendButtonTitle: String?

        switch transactionDecoration {
        case let decoration as OutgoingDecoration:
            type = .outgoingEvm(
                to: decoration.to,
                value: baseToken.decimalValue(value: decoration.value)
            )

        case let decoration as OutgoingEip20Decoration:
            if let token = try? coinManager.token(query: .init(blockchainType: baseToken.blockchainType, tokenType: .eip20(address: decoration.contractAddress.hex))) {
                type = .outgoingEip20(
                    to: decoration.to,
                    value: token.decimalValue(value: decoration.value),
                    token: token
                )
            }

        case let decoration as ApproveEip20Decoration:
            if let token = try? coinManager.token(query: .init(blockchainType: baseToken.blockchainType, tokenType: .eip20(address: decoration.contractAddress.hex))) {
                type = .approveEip20(
                    spender: decoration.spender,
                    value: token.decimalValue(value: decoration.value),
                    token: token
                )

                let isRevoke = decoration.value == 0

                customSendButtonTitle = isRevoke ? "send.confirmation.slide_to_revoke".localized : "send.confirmation.slide_to_approve".localized
            }
        default:
            ()
        }

        return EvmDecoration(
            type: type ?? .unknown(
                to: transactionData.to,
                value: baseToken.decimalValue(value: transactionData.value),
                input: transactionData.input,
                method: evmLabelManager.methodLabel(input: transactionData.input)
            ),
            customSendButtonTitle: customSendButtonTitle
        )
    }
}
