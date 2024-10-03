import MarketKit
import SwiftUI

enum TransactionField {
    case action(icon: String?, dimmed: Bool, title: String, value: String?)
    case amount(title: String, appValue: AppValue, rateValue: CurrencyValue?, type: AmountType, hidden: Bool)
    case noAmount(title: String, kind: AppValue.Kind)
    case nftAmount(iconUrl: String?, iconPlaceholderImageName: String, nftAmount: String, type: AmountType, providerCollectionUid: String?, nftUid: NftUid?)
    case value(title: String, description: ActionSheetView.InfoDescription?, appValue: AppValue?, currencyValue: CurrencyValue?, formatFull: Bool)
    case doubleValue(title: String, description: ActionSheetView.InfoDescription?, value1: String, value2: String?)
    case levelValue(title: String, value: String, level: ValueLevel)
    case memo(text: String)
    case address(title: String, value: String, blockchainType: BlockchainType)
    case price(title: String, tokenA: Token, tokenB: Token, amountA: Decimal, amountB: Decimal)
    case hex(title: String, value: String)
    case date(date: Date)
    case status(status: TransactionStatus)
    case id(value: String)
    case warning(text: String)
    case note(imageName: String, text: String)
    case explorer(title: String, url: String?)
    case option(option: Option)
    case rawTransaction
    case doubleSpend(txHash: String, conflictingTxHash: String)
    case lockInfo(lockState: TransactionLockState)

    @ViewBuilder var listRow: some View {
        switch self {
        case let .action(icon, dimmed, title, value):
            actionRow(icon: icon, dimmed: dimmed, title: title, value: value)
        case let .amount(title, appValue, rateValue, type, hidden):
            amountRow(title: title, kind: appValue.kind, value: appValue.value, rateValue: rateValue, type: type, hidden: hidden)
        case let .noAmount(title, kind):
            amountRow(title: title, kind: kind)
        case let .nftAmount(iconUrl, iconPlaceholderImageName, nftAmount, type, providerCollectionUid, nftUid):
            Text("NFT Amount")
        case let .value(title, description, appValue, currencyValue, formatFull):
            valueRow(title: title, description: description, appValue: appValue, currencyValue: currencyValue, formatFull: formatFull)
        case let .doubleValue(title, description, value1, value2):
            doubleValueRow(title: title, description: description, value1: value1, value2: value2)
        case let .levelValue(title, value, level):
            levelValueRow(title: title, value: value, level: level)
        case let .memo(text):
            levelValueRow(title: "tx_info.memo".localized, value: text, font: .themeSubhead1I, level: .regular)
        case let .address(title, value, blockchainType):
            RecipientRowsView(title: title, value: value, blockchainType: blockchainType)
        case let .price(title, tokenA, tokenB, amountA, amountB):
            PriceRow(title: title, tokenA: tokenA, tokenB: tokenB, amountA: amountA.magnitude, amountB: amountB.magnitude)
        case let .hex(title, value):
            hexRow(title: title, value: value)
        case let .date(date):
            levelValueRow(title: "tx_info.date".localized, value: DateHelper.instance.formatFullTime(from: date))
        case let .status(status):
            StatusRow(status: status)
        case let .id(value):
            IdRow(value: value)
        case let .warning(text):
            HighlightedTextView(text: text)
        case let .note(imageName, text):
            noteRow(imageName: imageName, text: text)
        case let .explorer(title, url):
            explorerRow(title: title, url: url)
        case let .option(option):
            Text("\(option)") // todo
        case .rawTransaction:
            rawTransactionRow()
        case let .doubleSpend(txHash, conflictingTxHash):
            DoubleSpendRow(txHash: txHash, conflictingTxHash: conflictingTxHash)
        case let .lockInfo(lockState):
            LockInfoRow(lockState: lockState)
        }
    }

    @ViewBuilder private func actionRow(icon: String?, dimmed: Bool, title: String, value: String?) -> some View {
        ListRow {
            if let icon {
                Image(icon).themeIcon(color: dimmed ? .themeGray : .themeLeah)
            }

            Text(title).textBody()
            Spacer()

            if let value {
                Text(value)
                    .textSubhead1()
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    @ViewBuilder private func amountRow(title: String, kind: AppValue.Kind, value: Decimal? = nil, rateValue: CurrencyValue? = nil, type: AmountType = .neutral, hidden: Bool = false) -> some View {
        ListRow {
            CoinIconView(coin: kind.coin)

            HStack(spacing: .margin4) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).textSubhead2(color: .themeLeah)

                    if let badge = kind.token?.fullBadge {
                        Text(badge).textCaption()
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    if let value {
                        let appValue = AppValue(kind: kind, value: value)

                        if let formatted = appValue.formattedFull(hidden: hidden) {
                            Text(formatted)
                                .textSubhead1(color: type.color)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text("n/a".localized)
                                .textSubhead1(color: .themeGray50)
                                .multilineTextAlignment(.trailing)
                        }

                        if let formatted = appValue.formattedFullCurrencyValue(rateValue: rateValue, hidden: hidden) {
                            Text(formatted)
                                .textCaption()
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        Text(kind.code)
                            .textSubhead1(color: type.color)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }

    @ViewBuilder private func valueRow(title: String, description: ActionSheetView.InfoDescription?, appValue: AppValue?, currencyValue: CurrencyValue?, formatFull: Bool) -> some View {
        ListRow(padding: EdgeInsets(top: .margin12, leading: description == nil ? .margin16 : 0, bottom: .margin12, trailing: .margin16)) {
            if let description {
                Text(title)
                    .textSubhead2()
                    .modifier(Informed(description: description))
            } else {
                Text(title)
                    .textSubhead2()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                if let formatted = (formatFull ? appValue?.formattedFull() : appValue?.formattedShort()) {
                    Text(formatted)
                        .textSubhead1(color: .themeLeah)
                        .multilineTextAlignment(.trailing)
                } else {
                    Text("n/a".localized)
                        .textSubhead1()
                        .multilineTextAlignment(.trailing)
                }

                if let formatted = (formatFull ? currencyValue?.formattedFull : currencyValue?.formattedShort) {
                    Text(formatted)
                        .textCaption()
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    @ViewBuilder private func doubleValueRow(title: String, description: ActionSheetView.InfoDescription?, value1: String, value2: String?) -> some View {
        ListRow(padding: EdgeInsets(top: .margin12, leading: description == nil ? .margin16 : 0, bottom: .margin12, trailing: .margin16)) {
            if let description {
                Text(title)
                    .textSubhead2()
                    .modifier(Informed(description: description))
            } else {
                Text(title)
                    .textSubhead2()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(value1)
                    .textSubhead1(color: .themeLeah)
                    .multilineTextAlignment(.trailing)

                if let value2 {
                    Text(value2)
                        .textSubhead1(color: .themeLeah)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    @ViewBuilder private func levelValueRow(title: String, value: String, font: Font = .themeSubhead1, level: ValueLevel = .regular) -> some View {
        ListRow {
            Text(title).textSubhead2()
            Spacer()
            Text(value)
                .font(font)
                .foregroundColor(color(valueLevel: level))
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder private func hexRow(title: String, value: String) -> some View {
        ListRow {
            Text(title).textSubhead2()

            Spacer()

            Text(value)
                .textSubhead1(color: .themeLeah)
                .lineLimit(3)
                .truncationMode(.middle)

            Button(action: {
                CopyHelper.copyAndNotify(value: value)
            }) {
                Image("copy_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))
        }
    }

    @ViewBuilder private func noteRow(imageName: String, text: String) -> some View {
        ListRow(spacing: .margin8) {
            Image(imageName).themeIcon()
            Text(text).themeSubhead2()
        }
    }

    @ViewBuilder private func explorerRow(title: String, url: String?) -> some View {
        ClickableRow {
            if let url {
                UrlManager.open(url: url)
                stat(page: .transactionInfo, event: .open(page: .externalBlockExplorer))
            }
        } content: {
            Image("globe_24").themeIcon()
            Text(title).textBody()
            Spacer()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func rawTransactionRow() -> some View {
        ListRow {
            Text("tx_info.raw_transaction".localized).themeSubhead2()
            Button(action: {
                CopyHelper.copyAndNotify(value: "") // todo
            }) {
                Image("copy_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))
        }
    }

    private func color(valueLevel: ValueLevel) -> Color {
        switch valueLevel {
        case .regular: return .themeLeah
        case .warning: return .themeJacob
        case .error: return .themeLucian
        }
    }
}

extension TransactionField {
    enum AppValueType {
        case regular(appValue: AppValue)
        case infinity(code: String)
        case withoutAmount(code: String)

        private func formatted(full: Bool) -> String? {
            switch self {
            case let .regular(appValue): return full ? appValue.formattedFull() : appValue.formattedShort()
            case let .infinity(code): return "∞ \(code)"
            case let .withoutAmount(code): return "\(code)"
            }
        }

        var formattedFull: String? {
            formatted(full: true)
        }

        var formattedShort: String? {
            formatted(full: false)
        }
    }

    enum AmountType {
        case incoming
        case outgoing
        case neutral

        var sign: FloatingPointSign {
            switch self {
            case .incoming, .neutral: return .plus
            case .outgoing: return .minus
            }
        }

        var signType: ValueFormatter.SignType {
            switch self {
            case .incoming, .outgoing: return .always
            case .neutral: return .never
            }
        }

        var color: Color {
            switch self {
            case .incoming: return .themeRemus
            case .outgoing: return .themeLucian
            case .neutral: return .themeLeah
            }
        }
    }

    enum Option {
        case resend(type: ResendTransactionType)
    }
}

extension TransactionField {
    struct StatusRow: View {
        let status: TransactionStatus

        @State private var infoPresented = false

        var body: some View {
            ListRow {
                Button {
                    infoPresented = true
                    stat(page: .transactionInfo, section: .status, event: .open(page: .info))
                } label: {
                    HStack(spacing: .margin8) {
                        Text("status".localized).textSubhead2()
                        Image.infoIcon
                    }
                }

                Spacer()

                HStack(spacing: .margin8) {
                    switch status {
                    case .pending:
                        Text("transactions.pending".localized).textSubhead1(color: .themeLeah)
                        ProgressView() // TODO: 0.2%
                    case .processing:
                        Text("transactions.processing".localized).textSubhead1(color: .themeLeah)
                        ProgressView() // TODO: progress * 0.8 + 0.2
                    case .completed:
                        Text("transactions.completed".localized).textSubhead1(color: .themeLeah)
                        Image("check_1_20").themeIcon(color: .themeRemus)
                    case .failed:
                        Text("transactions.failed".localized).textSubhead1(color: .themeLeah)
                        Image("warning_2_20").themeIcon(color: .themeLucian)
                    }
                }
            }
            .sheet(isPresented: $infoPresented) {
                InfoView(
                    items: [
                        .header1(text: "status_info.title".localized),
                        .header3(text: "status_info.pending.title".localized),
                        .text(text: "status_info.pending.content".localized(AppConfig.appName)),
                        .header3(text: "status_info.processing.title".localized),
                        .text(text: "status_info.processing.content".localized),
                        .header3(text: "status_info.completed.title".localized),
                        .text(text: "status_info.confirmed.content".localized),
                        .header3(text: "status_info.failed.title".localized),
                        .text(text: "status_info.failed.content".localized(AppConfig.appName)),
                    ],
                    isPresented: $infoPresented
                )
            }
        }
    }

    struct IdRow: View {
        let value: String

        @State private var shareText: String?

        var body: some View {
            ListRow {
                Text("tx_info.transaction_id".localized).textSubhead2()

                Spacer()

                HStack(spacing: .margin8) {
                    Button {
                        CopyHelper.copyAndNotify(value: value)
                        stat(page: .transactionInfo, event: .copy(entity: .transactionId))
                    } label: {
                        Text(value.shortened)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        shareText = value
                        stat(page: .transactionInfo, event: .share(entity: .transactionId))
                    } label: {
                        Image("share_1_20").renderingMode(.template)
                    }
                    .buttonStyle(SecondaryCircleButtonStyle())
                }
            }
            .sheet(item: $shareText) { shareText in
                ActivityView.view(activityItems: [shareText])
            }
        }
    }

    struct DoubleSpendRow: View {
        let txHash: String
        let conflictingTxHash: String

        @State private var infoPresented = false

        var body: some View {
            ClickableRow(spacing: .margin8) {
                infoPresented = true
            } content: {
                Image("double_send_24").themeIcon()
                Text("tx_info.double_spent_note".localized).themeSubhead2()
                Image.infoIcon
            }
            .sheet(isPresented: $infoPresented) {
                DoubleSpendView(txHash: txHash, conflictingTxHash: conflictingTxHash, isPresented: $infoPresented)
            }
        }
    }

    struct LockInfoRow: View {
        let lockState: TransactionLockState

        @State private var infoPresented = false

        var body: some View {
            let formattedDate = DateHelper.instance.formatFullTime(from: lockState.date)

            if lockState.locked {
                ClickableRow(spacing: .margin8) {
                    infoPresented = true
                } content: {
                    Image("lock_24").themeIcon()
                    Text("tx_info.locked_until".localized(formattedDate)).themeSubhead2()
                    Image.infoIcon
                }
                .sheet(isPresented: $infoPresented) {
                    InfoView(
                        items: [
                            .header1(text: "lock_info.title".localized),
                            .text(text: "lock_info.text".localized),
                        ],
                        isPresented: $infoPresented
                    )
                }
            } else {
                ListRow(spacing: .margin8) {
                    Image("unlock_24").themeIcon()
                    Text("tx_info.unlocked_at".localized(formattedDate)).themeSubhead2()
                }
            }
        }
    }

    struct DoubleSpendView: View {
        let txHash: String
        let conflictingTxHash: String
        @Binding var isPresented: Bool

        var body: some View {
            ThemeNavigationView {
                ThemeView {
                    ScrollView {
                        VStack(spacing: .margin16) {
                            HighlightedTextView(text: "double_spend_info.header".localized)

                            ListSection {
                                row(title: "double_spend_info.this_hash".localized, value: txHash)
                                row(title: "double_spend_info.conflicting_hash".localized, value: conflictingTxHash)
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                }
                .navigationTitle("double_spend_info.title".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("button.close".localized) {
                            isPresented = false
                        }
                    }
                }
            }
        }

        @ViewBuilder private func row(title: String, value: String) -> some View {
            ListRow {
                Text(title).themeSubhead2()

                Button {
                    CopyHelper.copyAndNotify(value: value)
                } label: {
                    Text(value.shortened)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}
