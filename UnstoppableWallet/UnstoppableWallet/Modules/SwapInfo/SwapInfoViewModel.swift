import Combine
import Foundation
import MarketKit
import RxSwift

class SwapInfoViewModel: ObservableObject {
    private let manager = Core.shared.swapHistoryManager
    private let rateService = HistoricalRateService(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager)

    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    private var swap: Swap
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

        self.swap = swap

        syncSections()
        syncLegs()
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        rates[rate.0] = rate.1
        syncSections()
    }

    private func syncSections() {
        let rateKeyIn = RateKey(token: swap.tokenIn, date: swap.date)
        let rateKeyOut = RateKey(token: swap.tokenOut, date: swap.date)

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
            .init([
                .simpleValue(
                    title: "swap_info.provider".localized,
                    value: SwapProviderFactory.providerName(id: swap.providerId) ?? swap.providerId
                ),
                .simpleValue(
                    title: "swap_info.date".localized,
                    value: DateHelper.instance.formatFullTime(from: swap.date)
                ),
                .swapStatus(status: swap.status),
                .recipient(
                    title: "swap_info.recipient".localized,
                    value: swap.toAddress,
                    copyable: true,
                    blockchainType: swap.tokenOut.blockchainType
                ),
            ], isMain: false),
        ]

        DispatchQueue.main.async {
            self.sections = sections
        }
    }

    private func syncLegs() {
        guard let fromAsset = swap.fromAsset, let toAsset = swap.toAsset, let swapLegs = swap.legs else {
            legs = []
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
}

extension SwapInfoViewModel {
    struct Leg {
        let title: String
        let status: Swap.Status
        let url: String?
    }
}
