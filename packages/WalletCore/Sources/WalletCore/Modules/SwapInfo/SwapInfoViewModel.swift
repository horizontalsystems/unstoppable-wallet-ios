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
        if !swap.status.isExpected {
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

        if let recipient = swap.recipient {
            fields.append(
                .recipient(
                    title: "swap_info.recipient".localized,
                    value: recipient,
                    copyable: true,
                    blockchainType: swap.tokenOut.blockchainType
                )
            )
        }

        let sections: [SendDataSection] = [
            .init([
                .amount(
                    token: swap.tokenIn,
                    appValueType: .regular(appValue: AppValue(token: swap.tokenIn, value: swap.amountIn)),
                    currencyValue: rates[rateKeyIn].map { CurrencyValue(currency: $0.currency, value: swap.amountIn * $0.value) },
                ),
                .amount(
                    token: swap.tokenOut,
                    appValueType: .regular(appValue: AppValue(token: swap.tokenOut, value: swap.amountOut)),
                    currencyValue: rates[rateKeyOut].map { CurrencyValue(currency: $0.currency, value: swap.amountOut * $0.value) },
                ),
            ], isFlow: true),
            .init(fields, isMain: false),
        ]

        DispatchQueue.main.async {
            self.sections = sections
        }
    }

    private func syncLegs() {
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

        legs = swapLegs.enumerated().map { _, leg in
            var title = "swap_info.unknown".localized

            if leg.type == USwapMultiSwapProvider.legTypeNativeSend {
                if leg.fromAsset == fromAsset {
                    title = "swap_info.deposit".localized(swap.tokenIn.coin.code)
                } else if leg.toAsset == toAsset {
                    title = "swap_info.send".localized(swap.tokenOut.coin.code)
                }
            } else if leg.type == USwapMultiSwapProvider.legTypeSwap {
                title = "swap_info.swap".localized
            }

            return Leg(title: title, status: leg.status, url: explorerUrl(chainId: leg.chainId, hash: leg.txHash))
        }
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

        guard let blockchainType = USwapMultiSwapProvider.blockchainTypeMap[chainId] else {
            return nil
        }

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
