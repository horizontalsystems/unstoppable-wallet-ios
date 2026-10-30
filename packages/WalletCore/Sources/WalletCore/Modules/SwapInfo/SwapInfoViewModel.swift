import Combine
import Foundation
import MarketKit
import RxSwift

class SwapInfoViewModel: ObservableObject {
    private let manager = Core.shared.swapHistoryManager
    private let providerInfoManager = Core.shared.swapProviderInfoManager
    private let reachabilityManager = Core.shared.reachabilityManager
    private let rateService = HistoricalRateService(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager)

    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    @Published private(set) var swap: Swap
    @Published private(set) var requestRefundLoading = false
    private var rates = [RateKey: CurrencyValue]()

    @Published var sections = [SendDataSection]()
    @Published var legs = [Leg]()

    init(swap: Swap) {
        self.swap = swap

        subscribe(&cancellables, manager.swapUpdatePublisher) { [weak self] in self?.handleUpdated(swap: $0) }
        subscribe(disposeBag, rateService.rateUpdatedObservable) { [weak self] in self?.handle(rate: $0) }

        for token in [swap.tokenIn, swap.tokenOut] {
            let rateKey = RateKey(token: token, date: swap.date)
            if let currencyValue = rateService.rate(key: rateKey) {
                rates[rateKey] = currencyValue
            } else {
                rateService.fetchRate(key: rateKey)
            }
        }

        syncSections()
        syncLegs()
    }

    private func handleUpdated(swap: Swap) {
        guard self.swap.uid == swap.uid else {
            return
        }

        DispatchQueue.main.async {
            self.swap = swap

            self.syncSections()
            self.syncLegs()
        }
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        rates[rate.0] = rate.1
        syncSections()
    }

    private func syncSections() {
        let rateKeyIn = RateKey(token: swap.tokenIn, date: swap.date)
        let rateKeyOut = RateKey(token: swap.tokenOut, date: swap.date)

        var fields: [SendField] = []
        if [.swap, .splitSwap].contains(swap.operation), !swap.status.isExpected {
            fields.append(
                .simpleValue(
                    title: "swap_info.provider".localized,
                    value: SwapProviderFactory.providerName(id: swap.providerId) ?? swap.providerId
                )
            )
        }

        fields.append(
            .simpleValue(
                title: "swap_info.date".localized,
                value: DateHelper.instance.formatFullTime(from: swap.date)
            )
        )

        if [.swap, .splitSwap].contains(swap.operation) {
            // The estimate captured when the swap was sent; single route, so no baseline.
            let precise = SwapProviderFactory.provider(id: swap.providerId)?.preciseEstimateTime ?? true
            if let timeState = MultiSwapViewModel.timeState(for: swap.estimatedTime, precise: precise, baseline: nil) {
                fields.append(
                    .simpleValue(
                        title: ComponentInformedTitle("swap.swapped_time".localized, info: .swapTime),
                        value: ComponentText(text: MultiSwapQuotesView.string(time: timeState.value), colorStyle: timeState.colorStyle)
                    )
                )
            }
        } else if swap.isPending, let estimatedTime = swap.estimatedTime {
            fields.append(
                .simpleValue(
                    title: "private_send.estimated_time".localized,
                    value: Duration.seconds(estimatedTime).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow))
                )
            )
        }

        if swap.operation != .privateSend, let recipient = swap.recipient {
            fields.append(
                .recipient(
                    title: "swap_info.recipient".localized,
                    value: recipient,
                    copyable: true,
                    blockchainType: swap.tokenOut.blockchainType
                )
            )
        }

        let amountIn = SendField.amount(
            token: swap.tokenIn,
            appValueType: .regular(appValue: AppValue(token: swap.tokenIn, value: swap.amountIn)),
            currencyValue: rates[rateKeyIn].map { CurrencyValue(currency: $0.currency, value: swap.amountIn * $0.value) }
        )

        let amountOut = SendField.amount(
            token: swap.tokenOut,
            appValueType: .regular(appValue: AppValue(token: swap.tokenOut, value: swap.amountOut)),
            currencyValue: rates[rateKeyOut].map { CurrencyValue(currency: $0.currency, value: swap.amountOut * $0.value) }
        )

        let flowSection: SendDataSection

        // the split layout needs every recipient's amount; until the track reports them it reads as one
        // swap followed by the recipients' addresses, which are known from the start
        if swap.operation == .splitSwap, let outputs = swap.outputs, !outputs.isEmpty {
            if outputs.allSatisfy({ $0.toAmount != nil }) {
                flowSection = splitFlowSection(amountIn: amountIn, outputs: outputs, rate: rates[rateKeyOut])
            } else {
                flowSection = splitRecipientsFlowSection(amountIn: amountIn, amountOut: amountOut, outputs: outputs)
            }
        } else {
            // Private send mirrors its confirmation: what the recipient gets, then the recipient
            let flowFields: [SendField] = switch swap.operation {
            case .privateSend: [amountOut] + (swap.recipient.map { [.address(value: $0, blockchainType: swap.tokenOut.blockchainType)] } ?? [])
            case .swap, .splitSwap, .crossPay: [amountIn, amountOut]
            }

            flowSection = .init(flowFields, isFlow: true)
        }

        let sections: [SendDataSection] = [
            flowSection,
            .init(fields, isMain: false),
        ]

        DispatchQueue.main.async {
            self.sections = sections
        }
    }

    /// Input, then an output + address pair per recipient, as on the split confirmation
    private func splitFlowSection(amountIn: SendField, outputs: [Swap.Output], rate: CurrencyValue?) -> SendDataSection {
        var fields = [amountIn]
        // dividers[i] sits after fields[i], so each one is added together with the field it precedes
        var dividers = [SendDataSection.FlowDivider]()
        let percents = Self.percents(outputs: outputs)

        for (position, output) in outputs.enumerated() {
            let amount = output.toAmount ?? 0

            dividers.append(position == 0 ? .arrow : .line)
            fields.append(
                .splitOutput(
                    token: swap.tokenOut,
                    percent: percents[position],
                    appValueType: .regular(appValue: AppValue(token: swap.tokenOut, value: amount)),
                    currencyValue: rate.map { CurrencyValue(currency: $0.currency, value: amount * $0.value) }
                )
            )

            if let toAddress = output.toAddress {
                dividers.append(.hidden)
                fields.append(
                    .recipient(
                        title: "swap.private.address".localized(output.index + 1),
                        value: toAddress,
                        copyable: true,
                        blockchainType: swap.tokenOut.blockchainType
                    )
                )
            }
        }

        return .init(fields, isFlow: true, flowDividers: dividers)
    }

    /// Input and the total output, then every recipient's address: the split before its payouts are known
    private func splitRecipientsFlowSection(amountIn: SendField, amountOut: SendField, outputs: [Swap.Output]) -> SendDataSection {
        var fields = [amountIn, amountOut]
        // dividers[i] sits after fields[i]
        var dividers: [SendDataSection.FlowDivider] = [.arrow]

        for output in outputs {
            guard let toAddress = output.toAddress else {
                continue
            }

            dividers.append(.line)
            fields.append(
                .recipient(
                    title: "swap.private.address".localized(output.index + 1),
                    value: toAddress,
                    copyable: true,
                    blockchainType: swap.tokenOut.blockchainType
                )
            )
        }

        return .init(fields, isFlow: true, flowDividers: dividers)
    }

    /// Each output's share of the deposit; the last one takes the rounding remainder so they add up to 100
    static func percents(outputs: [Swap.Output]) -> [Int] {
        // One unit for every output: the deposit shares (tokenIn) when all are known, else the payouts (tokenOut)
        let fromAmounts = outputs.compactMap(\.fromAmount)
        let amounts = fromAmounts.count == outputs.count ? fromAmounts : outputs.map { $0.toAmount ?? 0 }
        let total = amounts.reduce(0, +)

        guard total > 0 else {
            return outputs.map { _ in 0 }
        }

        var percents = amounts.dropLast().map { amount in
            NSDecimalNumber(decimal: amount / total * 100).rounding(accordingToBehavior: nil).intValue
        }
        percents.append(100 - percents.reduce(0, +))

        return percents
    }

    private func syncLegs() {
        // A split shows its recipients from the first poll on, before the track reports any asset or leg
        if swap.operation == .splitSwap, let outputs = swap.outputs, !outputs.isEmpty {
            legs = splitLegs(outputs: outputs)
            return
        }

        guard let fromAsset = swap.fromAsset, let toAsset = swap.toAsset, let swapLegs = swap.legs else {
            if swap.status == .actionRequired {
                legs = actionRequiredLegs(existingLegs: [])
            } else {
                legs = []
            }
            return
        }

        if swap.status == .actionRequired {
            legs = actionRequiredLegs(existingLegs: swapLegs)
            return
        }

        legs = swapLegs.map { leg(leg: $0, fromAsset: fromAsset, toAsset: toAsset) }
    }

    /// One shared deposit step on top, from the split's top-level deposit leg, followed by each recipient's
    /// own steps, numbered by recipient. Rows stored by the former track shape carry a deposit leg per
    /// output, all flattened into `swap.legs`: they share the deposit hash and collapse into one step, and
    /// are left out of the outputs' own steps.
    private func splitLegs(outputs: [Swap.Output]) -> [Leg] {
        let fromAsset = swap.fromAsset
        let toAsset = swap.toAsset
        let isDeposit: (Swap.Leg) -> Bool = {
            $0.type == USwapMultiSwapProvider.legTypeNativeSend && $0.outputIndex == nil && fromAsset != nil && $0.fromAsset == fromAsset
        }

        var depositGroups = [(txHash: String, legs: [Swap.Leg])]()
        for depositLeg in (swap.legs ?? []).filter(isDeposit) {
            if let index = depositGroups.firstIndex(where: { $0.txHash == depositLeg.txHash }) {
                depositGroups[index].legs.append(depositLeg)
            } else {
                depositGroups.append((txHash: depositLeg.txHash, legs: [depositLeg]))
            }
        }

        var depositLegs = depositGroups.compactMap { group -> Leg? in
            guard let first = group.legs.first else {
                return nil
            }

            return Leg(
                title: "swap_info.deposit".localized(swap.tokenIn.coin.code),
                status: group.legs.first(where: { $0.status != .completed })?.status ?? .completed,
                url: group.txHash.isEmpty ? nil : explorerUrl(chainId: first.chainId, hash: group.txHash)
            )
        }

        // Not observed yet: the deposit is on its way, or never arrived for a split that already ended
        if depositLegs.isEmpty {
            let status: Swap.Status = switch swap.status {
            case .notStarted, .completed, .failed, .refunded, .expired: swap.status
            case .signed, .pending, .swapping, .actionRequired, .unknown: .pending
            }

            depositLegs = [
                Leg(
                    title: "swap_info.deposit".localized(swap.tokenIn.coin.code),
                    status: status,
                    url: swap.txHash.flatMap { explorerUrl(blockchainType: swap.tokenIn.blockchainType, hash: $0) }
                ),
            ]
        }

        let outputLegs = outputs.flatMap { output -> [Leg] in
            let recipientNumber = output.index + 1
            let trackedLegs = output.legs.filter { !isDeposit($0) }

            // Every recipient shows a row from the first poll on, at its output's status until its payout is reported
            guard !trackedLegs.isEmpty else {
                return [
                    Leg(
                        title: "swap_info.receive".localized("\(swap.tokenOut.coin.code) \(recipientNumber)"),
                        status: output.status,
                        url: nil
                    ),
                ]
            }

            return trackedLegs.map { leg(leg: $0, fromAsset: fromAsset, toAsset: toAsset, recipientNumber: recipientNumber) }
        }

        return depositLegs + outputLegs
    }

    private func leg(leg: Swap.Leg, fromAsset: String?, toAsset: String?, recipientNumber: Int? = nil) -> Leg {
        var title = "swap_info.unknown".localized

        if leg.refund {
            let code = recipientNumber.map { "\(swap.tokenIn.coin.code) \($0)" } ?? swap.tokenIn.coin.code
            title = "swap_info.refund".localized(code)
        } else if leg.type == USwapMultiSwapProvider.legTypeNativeSend {
            if leg.outputIndex == nil, leg.fromAsset == fromAsset {
                title = "swap_info.deposit".localized(swap.tokenIn.coin.code)
            } else if leg.outputIndex != nil || leg.toAsset == toAsset {
                // a split's payout leg is a receive even while the track leaves the shared `toAsset` empty
                let code = recipientNumber.map { "\(swap.tokenOut.coin.code) \($0)" } ?? swap.tokenOut.coin.code
                title = "swap_info.receive".localized(code)
            }
        } else if leg.type == USwapMultiSwapProvider.legTypeSwap {
            title = recipientNumber.map { "\("swap_info.swap".localized) \($0)" } ?? "swap_info.swap".localized
        }

        return Leg(
            title: title,
            status: leg.status,
            url: leg.txHash.isEmpty ? nil : explorerUrl(chainId: leg.chainId, hash: leg.txHash)
        )
    }

    private func actionRequiredLegs(existingLegs: [Swap.Leg]) -> [Leg] {
        if isSingleChain {
            return [
                Leg(
                    title: "swap_info.swap".localized,
                    status: .failed,
                    url: existingLegs.first.map { explorerUrl(chainId: $0.chainId, hash: $0.txHash) } ?? nil
                ),
            ]
        }

        let depositLeg = existingLegs.first { $0.type == USwapMultiSwapProvider.legTypeNativeSend && $0.fromAsset == swap.fromAsset }
        let swapLeg = existingLegs.first { $0.type == USwapMultiSwapProvider.legTypeSwap }

        return [
            Leg(
                title: "swap_info.deposit".localized(swap.tokenIn.coin.code),
                status: .completed,
                url: depositLeg.map { explorerUrl(chainId: $0.chainId, hash: $0.txHash) } ?? nil
            ),
            Leg(
                title: "swap_info.swap".localized,
                status: .failed,
                url: swapLeg.map { explorerUrl(chainId: $0.chainId, hash: $0.txHash) } ?? nil
            ),
        ]
    }

    private var isSingleChain: Bool {
        swap.tokenIn.blockchainType == swap.tokenOut.blockchainType
    }

    private func explorerUrl(chainId: String, hash: String) -> String? {
        switch chainId {
        case "thorchain-1": return "https://thorchain.net/tx/" + hash
        case "near": return "https://nearblocks.io/txns/" + hash
        default: ()
        }

        guard let blockchainType = USwapAssetRepository.blockchainTypeMap[chainId] else {
            return nil
        }

        return explorerUrl(blockchainType: blockchainType, hash: hash)
    }

    private func explorerUrl(blockchainType: BlockchainType, hash: String) -> String? {
        if blockchainType.isEvm {
            return Core.shared.evmSyncSourceManager.syncSource(blockchainType: blockchainType).transactionSource.transactionUrl(hash: hash)
        }

        switch blockchainType {
        case .bitcoin: return "https://blockchair.com/bitcoin/transaction/" + hash
        case .bitcoinCash: return "https://blockchair.com/bitcoin-cash/transaction/" + hash
        case .dash: return "https://blockchair.com/dash/transaction/" + hash
        case .ecash: return "https://blockchair.com/ecash/transaction/" + hash
        case .litecoin: return "https://blockchair.com/litecoin/transaction/" + hash
        case .monero: return "https://blockchair.com/monero/transaction/" + hash
        case .zcash: return "https://blockchair.com/zcash/transaction/" + hash
        case .stellar: return "https://stellar.expert/explorer/public/tx/" + hash
        case .ton: return "https://tonviewer.com/transaction/" + hash
        case .zano: return "https://explorer.zano.org/transaction/" + hash
        case .tron: return "https://tronscan.org/#/transaction/" + hash
        default: return nil
        }
    }

    @MainActor func preloadRefundContacts() async {
        if providerInfoManager.hasCache {
            return
        }

        guard reachabilityManager.isReachable else {
            return
        }

        requestRefundLoading = true

        defer {
            requestRefundLoading = false
        }

        await preloadRefundContacts(timeout: 6)
    }

    private func preloadRefundContacts(timeout: TimeInterval) async {
        providerInfoManager.startPreload()

        let startedAt = Date()
        while !providerInfoManager.hasCache, Date().timeIntervalSince(startedAt) < timeout {
            try? await Task.sleep(seconds: 0.1)
        }
    }
}

extension SwapInfoViewModel {
    struct Leg {
        let title: String
        let status: Swap.Status
        let url: String?
    }
}
