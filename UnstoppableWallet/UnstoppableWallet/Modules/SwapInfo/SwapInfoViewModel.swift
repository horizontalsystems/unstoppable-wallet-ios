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

        buildSections()
    }

    private func handleUpdated(swap: Swap) {
        guard self.swap.uid == swap.uid else {
            return
        }

        self.swap = swap
        buildSections()
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        rates[rate.0] = rate.1
        buildSections()
    }

    private func buildSections() {
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
                .simpleValue(
                    title: "swap_info.status".localized,
                    value: swap.status.title
                ),
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
}
