import MarketKit
import SwiftUI

enum TransactionInfoModule {
    static func present(transactionRecord: TransactionRecord) {
        guard let viewModel = viewModel(transactionRecord: transactionRecord) else {
            return
        }

        Coordinator.shared.present { isPresented in
            TransactionInfoView(viewModel: viewModel, isPresented: isPresented)
        }
    }

    private static func viewModel(transactionRecord: TransactionRecord) -> TransactionInfoViewModel? {
        guard let adapter = Core.shared.transactionAdapterManager.adapter(for: transactionRecord.source) else {
            return nil
        }
        let rateService = HistoricalRateService(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager)

        let service = TransactionInfoService(transactionRecord: transactionRecord, adapter: adapter, currencyManager: Core.shared.currencyManager, rateService: rateService, balanceHiddenManager: Core.shared.balanceHiddenManager)
        let contactLabelService = ContactLabelService(contactManager: Core.shared.contactManager, blockchainType: transactionRecord.source.blockchainType)
        // speed up and cancel replace a pending transaction, which a watch account cannot sign
        let watchAccount = Core.shared.accountManager.activeAccount?.watchAccount ?? false
        let actionEnabled = transactionRecord.source.blockchainType.resendable && !watchAccount
        let factory = TransactionInfoViewItemFactory(evmLabelManager: Core.shared.evmLabelManager, contactLabelService: contactLabelService, actionEnabled: actionEnabled, extraProviderFactory: Core.shared.transactionInfoExtraFactory)

        return TransactionInfoViewModel(service: service, factory: factory, contactLabelService: contactLabelService, adapter: adapter)
    }
}

extension TransactionInfoModule {
    enum Option {
        case resend(type: ResendTransactionType)
        case zcashResend
    }

    enum AmountType {
        case incoming
        case outgoing
        case neutral
        case secondary

        var signType: ValueFormatter.SignType {
            switch self {
            case .incoming, .outgoing, .secondary: return .always
            case .neutral: return .never
            }
        }

        var sign: FloatingPointSign {
            switch self {
            case .incoming, .neutral, .secondary: return .plus
            case .outgoing: return .minus
            }
        }

        var colorStyle: ColorStyle {
            switch self {
            case .incoming: return .green
            case .outgoing, .neutral: return .primary
            case .secondary: return .secondary
            }
        }
    }

    enum ViewItem {
        case actionTitle(iconName: String?, iconDimmed: Bool, title: String, subTitle: String?)
        case amount(title: String, subtitle: String?, iconUrl: String?, iconAlternativeUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType, coin: Coin?)
        /// notProcessed: failed without reaching the chain, which is not an error to show as one.
        case status(status: TransactionStatus, notProcessed: Bool = false)
        case option(option: Option)
        case date(date: Date)
        case from(value: String, valueTitle: String?, contactAddress: ContactAddress?)
        case to(value: String, valueTitle: String?, contactAddress: ContactAddress?)
        case spender(value: String, valueTitle: String?, contactAddress: ContactAddress?)
        case recipient(value: String, valueTitle: String?, contactAddress: ContactAddress?)
        case contactName(name: String)
        case id(value: String)
        case rate(value: String)
        case fee(title: String, value: String)
        case price(price: String)
        case doubleSpend(txHash: String, conflictingTxHash: String)
        case lockInfo(lockState: TransactionLockState)
        case sentToSelf
        case rawTransaction
        case memo(text: String)
        case txSecretKey(text: String)
        case service(value: String)
        case value(title: String, value: String)
        case explorer(title: String, url: String?)
        case warning(text: String)
    }

    struct SectionViewItem {
        let viewItems: [ViewItem]
        let footer: String?

        init(_ viewItems: [ViewItem], footer: String? = nil) {
            self.viewItems = viewItems
            self.footer = footer
        }
    }
}
