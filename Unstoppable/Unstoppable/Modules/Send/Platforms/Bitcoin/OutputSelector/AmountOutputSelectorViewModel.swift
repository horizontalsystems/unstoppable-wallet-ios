import Combine
import RxSwift

class AmountOutputSelectorViewModel: ObservableObject {
    let disposeBag = DisposeBag()
    let fiatService: FiatService

    @Published var viewItem: ViewItem? = nil

    init(fiatService: FiatService) {
        self.fiatService = fiatService

        subscribe(disposeBag, fiatService.primaryInfoObservable) { [weak self] _ in self?.updateViewItem() }
        updateViewItem()
    }

    private func updateViewItem() {
        var primaryText: String?
        switch fiatService.primaryInfo {
        case let .amount(amount):
            primaryText = ValueFormatter.instance.formatFull(value: amount, decimalCount: fiatService.token?.decimals ?? 8)
        case let .amountInfo(amountInfo):
            primaryText = amountInfo?.formattedFull
        }

        var secondaryText: String?
        if let secondaryInfo = fiatService.secondaryAmountInfo {
            secondaryText = secondaryInfo.formattedFull
        }

        viewItem = primaryText.map { ViewItem(title: $0, subtitle: secondaryText) }
    }
}

extension AmountOutputSelectorViewModel {
    struct ViewItem {
        let title: String
        let subtitle: String?
    }
}
