import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinInvestorsViewModel {
    private let service: CoinInvestorsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: CoinInvestorsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<[CoinInvestment]>) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .completed(let investments):
            viewItemsRelay.accept(investments.map { viewItem(investment: $0) })
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func viewItem(investment: CoinInvestment) -> ViewItem {
        ViewItem(
                amount: investment.amount.flatMap { CurrencyCompactFormatter.instance.format(currency: service.usdCurrency, value: $0) } ?? "---",
                info: "\(investment.round) - \(DateHelper.instance.formatFullDateOnly(from: investment.date))",
                fundViewItems: investment.funds.map { fundViewItem(fund: $0) }
        )
    }

    private func fundViewItem(fund: CoinInvestment.Fund) -> FundViewItem {
        FundViewItem(
                uid: fund.uid,
                name: fund.name,
                logoUrl: fund.logoUrl,
                isLead: fund.isLead,
                url: fund.website
        )
    }

}

extension CoinInvestorsViewModel {

    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension CoinInvestorsViewModel {

    struct ViewItem {
        let amount: String
        let info: String
        let fundViewItems: [FundViewItem]
    }

    struct FundViewItem {
        let uid: String
        let name: String
        let logoUrl: String
        let isLead: Bool
        let url: String
    }

}
