import Foundation
import MarketKit

/// Maps a swap of the Swaps, Privates and CrossPay lists to its activity row
enum SwapCellViewItemFactory {
    static func glyph(operation: Swap.Operation) -> String {
        switch operation {
        case .swap: return "swap_e"
        case .splitSwap: return "private_swap"
        case .privateSend: return "private_send"
        case .crossPay: return "double_arrow"
        }
    }

    static func state(status: Swap.Status) -> ActivityCellViewItem.State {
        switch status {
        case .notStarted, .signed, .pending, .swapping: return .pending
        case .completed: return .completed
        case .failed: return .failed
        case .refunded, .expired, .unknown: return .inactive
        case .actionRequired: return .attention
        }
    }

    /// The step a pending swap is at, as Swap Info shows it: the last step in progress; before any step starts,
    /// the first one not done (the last one when the steps are done ahead of the swap's status); without steps,
    /// the swap itself for a direct one, else the deposit Swap Info would show first.
    private static func pendingSubtitle(swap: Swap, legs: [SwapLegsBuilder.Leg]) -> String {
        let title: String

        if let leg = legs.last(where: \.isInProgress) {
            title = leg.title
        } else if let leg = legs.first(where: { !$0.isDone }) ?? legs.last {
            title = leg.title
        } else if isDirect(swap: swap) {
            title = "swap_info.swap".localized
        } else {
            title = "swap_info.deposit".localized(swap.tokenIn.coin.code)
        }

        return "swap_info.pending_step".localized(title)
    }

    /// A swap the wallet broadcasts itself on one chain, as a DEX swap: there is no deposit to wait for
    private static func isDirect(swap: Swap) -> Bool {
        swap.depositAddress == nil && swap.tokenIn.blockchainType == swap.tokenOut.blockchainType
    }

    /// The address a Private Send or CrossPay delivers to, shown in its row once done
    static func recipientAddress(swap: Swap) -> String {
        swap.recipient ?? swap.toAddress
    }

    /// `recipientName` is the contact or label of `recipientAddress(swap:)`; without one, the address is shortened
    static func subtitle(swap: Swap, legs: [SwapLegsBuilder.Leg], recipientName: String? = nil) -> String {
        switch state(status: swap.status) {
        case .pending:
            switch swap.operation {
            case .privateSend: return "transactions.pending.sending".localized
            case .swap, .splitSwap, .crossPay: return pendingSubtitle(swap: swap, legs: legs)
            }
        case .completed:
            switch swap.operation {
            case .swap, .splitSwap: return "transactions.swap".localized
            case .privateSend, .crossPay: return "transactions.to".localized(recipientName ?? recipientAddress(swap: swap).shortened)
            }
        case .failed:
            switch swap.operation {
            case .swap, .splitSwap: return "transactions.failed.swap".localized
            case .privateSend, .crossPay: return "transactions.failed.transfer".localized
            }
        case .inactive, .attention:
            return swap.status.title
        }
    }

    static func viewItem(
        swap: Swap,
        legs: [SwapLegsBuilder.Leg],
        amountIn: String?,
        amountOut: String?,
        fiatIn: String?,
        recipientName: String? = nil,
        balanceHidden: Bool
    ) -> ActivityCellViewItem {
        let tokens: [ActivityCellViewItem.Token]
        var primaryValue: ActivityCellViewItem.Value
        var secondaryValue: ActivityCellViewItem.Value?

        switch swap.operation {
        case .swap, .splitSwap:
            tokens = [token(swap.tokenIn), token(swap.tokenOut)]
            // a swap paid to another recipient is not received by the wallet, as in the transactions list
            let outType: ActivityCellViewItem.ValueType = swap.operation == .swap && swap.recipient != nil ? .secondary : .incoming
            primaryValue = .init(text: amountOut.map { "+\($0)" } ?? unknownText, type: outType)
            secondaryValue = .init(text: amountIn.map { "-\($0)" } ?? unknownText, type: .outgoing)
        case .crossPay:
            tokens = [token(swap.tokenIn), token(swap.tokenOut)]
            primaryValue = .init(text: amountIn.map { "-\($0)" } ?? unknownText, type: .outgoing)
            secondaryValue = .init(text: amountOut ?? unknownText, type: .secondary)
        case .privateSend:
            tokens = [token(swap.tokenIn)]
            primaryValue = .init(text: amountIn.map { "-\($0)" } ?? unknownText, type: .outgoing)
            secondaryValue = fiatIn.map { .init(text: "-\($0)", type: .secondary) }
        }

        if balanceHidden {
            primaryValue = .init(text: BalanceHiddenManager.placeholder, type: primaryValue.type)
            secondaryValue = .init(text: BalanceHiddenManager.placeholder, type: secondaryValue?.type ?? .neutral)
        }

        return ActivityCellViewItem(
            glyph: glyph(operation: swap.operation),
            state: state(status: swap.status),
            tokens: tokens,
            subtitle: subtitle(swap: swap, legs: legs, recipientName: recipientName),
            primaryValue: primaryValue,
            secondaryValue: secondaryValue,
            doubleSpend: false,
            locked: nil,
            dimmed: false
        )
    }

    /// a missing amount, as the transaction rows show one
    private static let unknownText = ActivityCellViewItem.Token.unknownText

    private static func token(_ token: Token) -> ActivityCellViewItem.Token {
        ActivityCellViewItem.Token(
            icon: .remote(url: token.coin.imageUrl, alternativeUrl: token.coin.image, placeholder: "placeholder_circle", type: .circle),
            text: token.coin.code
        )
    }
}
