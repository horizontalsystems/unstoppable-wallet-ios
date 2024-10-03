import Foundation
import MarketKit

class TransactionRecord {
    let source: TransactionSource
    let uid: String
    let transactionHash: String
    let transactionIndex: Int
    let blockHeight: Int?
    let confirmationsThreshold: Int?
    let date: Date
    let failed: Bool
    let spam: Bool

    init(source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, failed: Bool, spam: Bool = false) {
        self.source = source
        self.uid = uid
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
        self.blockHeight = blockHeight
        self.confirmationsThreshold = confirmationsThreshold
        self.date = date
        self.failed = failed
        self.spam = spam
    }

    func status(lastBlockHeight: Int?) -> TransactionStatus {
        if failed {
            return .failed
        } else if let blockHeight, let lastBlockHeight {
            let threshold = confirmationsThreshold ?? 1
            let confirmations = lastBlockHeight - blockHeight + 1

            if confirmations >= threshold {
                return .completed
            } else {
                return .processing(progress: Double(max(0, confirmations)) / Double(threshold))
            }
        }

        return .pending
    }

    func lockState(lastBlockTimestamp _: Int?) -> TransactionLockState? {
        nil
    }

    open var mainValue: AppValue? {
        nil
    }

    var rateTokens: [Token?] {
        []
    }

    var feeInfo: (AppValue, Bool)? {
        nil
    }

    func sections(
        lastBlockInfo: LastBlockInfo?,
        rates: [Coin: CurrencyValue],
        nftMetadata: [NftUid: NftAssetBriefMetadata],
        explorerTitle: String,
        explorerUrl: String?,
        hidden: Bool
    ) -> [Section] {
        var sections = [Section]()

        if spam {
            sections.append(.init(fields: [.warning(text: "tx_info.scam_warning".localized)]))
        }

        let status = status(lastBlockHeight: lastBlockInfo?.height)

        sections.append(contentsOf: internalSections(status: status, lastBlockInfo: lastBlockInfo, rates: rates, nftMetadata: nftMetadata, hidden: hidden))

        var fields: [TransactionField] = [
            .date(date: date),
            .status(status: status),
        ]

        if let (fee, showEstimate) = feeInfo {
            fields.append(
                .levelValue(
                    title: showEstimate && status.isPending ? "tx_info.fee.estimated".localized : "tx_info.fee".localized,
                    value: AmountData(appValue: fee, rate: fee.coin.flatMap { rates[$0] }).formattedFull,
                    level: .regular
                )
            )
        }

        fields.append(.id(value: transactionHash))

        sections.append(.init(fields: fields))

        if source.blockchainType.resendable, isResendable(status: status) {
            sections.append(.init(
                fields: [
                    .option(option: .resend(type: .speedUp)),
                    .option(option: .resend(type: .cancel)),
                ],
                footer: "tx_info.resend_description".localized
            ))
        }

        sections.append(.init(fields: [
            .explorer(title: "tx_info.view_on".localized(explorerTitle), url: explorerUrl),
        ]))

        return sections
    }

    func internalSections(status _: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates _: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden _: Bool) -> [Section] {
        []
    }

    func isResendable(status _: TransactionStatus) -> Bool {
        false
    }

    func type(appValue: AppValue, condition: Bool = true, _ trueType: TransactionField.AmountType, _ falseType: TransactionField.AmountType? = nil) -> TransactionField.AmountType {
        guard !appValue.zeroValue else {
            return .neutral
        }

        return condition ? trueType : (falseType ?? trueType)
    }

    func rate(rateValue: CurrencyValue?, code: String) -> TransactionField? {
        guard let rateValue, let formattedValue = ValueFormatter.instance.formatFull(currencyValue: rateValue) else {
            return nil
        }

        return .levelValue(title: "tx_info.rate".localized, value: "balance.rate_per_coin".localized(formattedValue, code), level: .regular)
    }

    private func nftAmount(appValue: AppValue, type: TransactionField.AmountType, metadata: NftAssetBriefMetadata?, hidden: Bool) -> TransactionField {
        .nftAmount(
            iconUrl: metadata?.previewImageUrl,
            iconPlaceholderImageName: "placeholder_nft_32",
            nftAmount: hidden ? BalanceHiddenManager.placeholder : appValue.formattedFull(signType: type.signType) ?? "n/a".localized,
            type: type,
            providerCollectionUid: metadata?.providerCollectionUid,
            nftUid: metadata?.nftUid
        )
    }

    func receiveFields(appValue: AppValue, from: String?, mint: Bool = false, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata] = [:], memo: String? = nil, status: TransactionStatus? = nil, hidden: Bool) -> [TransactionField] {
        var fields = [TransactionField]()

        var rateField: TransactionField?

        switch appValue.kind {
        case let .nft(nftUid, tokenName, _):
            fields.append(
                .action(
                    icon: "arrow_medium_2_down_left_24",
                    dimmed: true,
                    title: mint ? "transactions.mint".localized : "transactions.receive".localized,
                    value: nftMetadata[nftUid]?.name ?? tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
                )
            )

            fields.append(
                nftAmount(
                    appValue: appValue,
                    type: type(appValue: appValue, .incoming),
                    metadata: nftMetadata[nftUid],
                    hidden: hidden
                )
            )
        default:
            let rateValue = appValue.coin.flatMap { rates[$0] }

            fields.append(
                .amount(
                    title: mint ? "transactions.mint".localized : "transactions.receive".localized,
                    appValue: appValue,
                    rateValue: rateValue,
                    type: type(appValue: appValue, .incoming),
                    hidden: hidden
                )
            )

            rateField = rate(rateValue: rateValue, code: appValue.code)
        }

        if !mint, let from {
            fields.append(.address(title: "tx_info.from_hash".localized, value: from, blockchainType: source.blockchainType))
        }

        if let rateField {
            fields.append(rateField)
        }

        if let memo {
            fields.append(.memo(text: memo))
        }

        if let status {
            fields.append(.status(status: status))
        }

        return fields
    }

    func sendFields(appValue: AppValue, to: String?, burn: Bool = false, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata] = [:], sentToSelf: Bool = false, hidden: Bool) -> [TransactionField] {
        var fields = [TransactionField]()

        var rateField: TransactionField?

        switch appValue.kind {
        case let .nft(nftUid, tokenName, _):
            fields.append(
                .action(
                    icon: burn ? "flame_24" : "arrow_medium_2_up_right_24",
                    dimmed: true,
                    title: burn ? "transactions.burn".localized : "transactions.send".localized,
                    value: nftMetadata[nftUid]?.name ?? tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
                )
            )

            fields.append(
                nftAmount(
                    appValue: appValue,
                    type: type(appValue: appValue, condition: sentToSelf, .neutral, .outgoing),
                    metadata: nftMetadata[nftUid],
                    hidden: hidden
                )
            )
        default:
            let rateValue = appValue.coin.flatMap { rates[$0] }

            fields.append(
                .amount(
                    title: burn ? "transactions.burn".localized : "transactions.send".localized,
                    appValue: appValue,
                    rateValue: rateValue,
                    type: type(appValue: appValue, condition: sentToSelf, .neutral, .outgoing),
                    hidden: hidden
                )
            )

            rateField = rate(rateValue: rateValue, code: appValue.code)
        }

        if !burn, let to {
            fields.append(.address(title: "tx_info.to_hash".localized, value: to, blockchainType: source.blockchainType))
        }

        if let rateField {
            fields.append(rateField)
        }

        return fields
    }

    func sentToSelfField() -> TransactionField {
        .note(imageName: "arrow_return_24", text: "tx_info.to_self_note".localized)
    }

    func youPayString(status: TransactionStatus) -> String {
        if case .completed = status {
            return "tx_info.you_paid".localized
        } else {
            return "tx_info.you_pay".localized
        }
    }

    func youGetString(status: TransactionStatus) -> String {
        if case .completed = status {
            return "tx_info.you_got".localized
        } else {
            return "tx_info.you_get".localized
        }
    }

    static func isSpam(appValues: [AppValue]) -> Bool {
        let stableCoinUids = ["tether", "usd-coin", "dai", "binance-usd", "binance-peg-busd", "stasis-eurs"]

        for appValue in appValues {
            let value = appValue.value

            switch appValue.kind {
            case let .token(token):
                if stableCoinUids.contains(token.coin.uid) {
                    if value > 0.01 {
                        return false
                    }
                } else if value > 0 {
                    return false
                }
            case let .coin(coin, _):
                if stableCoinUids.contains(coin.uid) {
                    if value > 0.01 {
                        return false
                    }
                } else if value > 0 {
                    return false
                }
            case .nft:
                if value > 0 {
                    return false
                }
            default: ()
            }
        }

        return true
    }
}

extension TransactionRecord {
    struct Section {
        let fields: [TransactionField]
        let footer: String?

        init(fields: [TransactionField], footer: String? = nil) {
            self.fields = fields
            self.footer = footer
        }
    }
}

extension TransactionRecord: Comparable {
    public static func < (lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        guard lhs.date == rhs.date else {
            return lhs.date > rhs.date
        }

        guard lhs.transactionIndex == rhs.transactionIndex else {
            return lhs.transactionIndex > rhs.transactionIndex
        }

        return lhs.uid > rhs.uid
    }

    public static func == (lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        lhs.uid == rhs.uid
    }
}

enum TransactionStatus {
    case failed
    case pending
    case processing(progress: Double)
    case completed

    var isPendingOrProcessing: Bool {
        switch self {
        case .pending, .processing: return true
        default: return false
        }
    }

    var isPending: Bool {
        switch self {
        case .pending: return true
        default: return false
        }
    }
}

extension TransactionStatus: Equatable {
    public static func == (lhs: TransactionStatus, rhs: TransactionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.failed, .failed): return true
        case (.pending, .pending): return true
        case let (.processing(lhsProgress), .processing(rhsProgress)): return lhsProgress == rhsProgress
        case (.completed, .completed): return true
        default: return false
        }
    }
}

extension TransactionRecord {
    var nftUids: Set<NftUid> {
        var nftUids = Set<NftUid>()

        switch self {
        case let record as EvmOutgoingTransactionRecord:
            if let nftUid = record.value.nftUid {
                nftUids.insert(nftUid)
            }

        case let record as ContractCallTransactionRecord:
            nftUids.formUnion(Set((record.incomingEvents + record.outgoingEvents).compactMap(\.value.nftUid)))

        case let record as ExternalContractCallTransactionRecord:
            nftUids.formUnion(Set((record.incomingEvents + record.outgoingEvents).compactMap(\.value.nftUid)))

        default: ()
        }

        return nftUids
    }
}

extension [TransactionRecord] {
    var nftUids: Set<NftUid> {
        var nftUids = Set<NftUid>()

        for record in self {
            nftUids = nftUids.union(record.nftUids)
        }

        return nftUids
    }
}
