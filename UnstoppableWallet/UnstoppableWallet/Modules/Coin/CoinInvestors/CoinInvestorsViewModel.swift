import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinInvestorsViewModel {
    private let service: CoinInvestorsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

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
            syncErrorRelay.accept(false)
        case .completed(let investments):
            viewItemsRelay.accept(investments.map { viewItem(investment: $0) })
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        }
    }

    private func viewItem(investment: CoinInvestment) -> ViewItem {
        ViewItem(
                amount: investment.amount.flatMap { ValueFormatter.instance.formatShort(currency: service.usdCurrency, value: $0) } ?? "---",
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

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onTapRetry() {
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
