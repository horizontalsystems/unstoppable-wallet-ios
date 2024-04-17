import Combine
import RxSwift

class CexWithdrawConfirmViewModel {
    private let service: CexWithdrawConfirmService
    private let coinService: CexCoinService
    private let contactLabelService: ContactLabelService?
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    @Published private(set) var sectionViewItems = [SectionViewItem]()
    @Published private(set) var withdrawing = false

    init(service: CexWithdrawConfirmService, coinService: CexCoinService, contactLabelService: ContactLabelService?) {
        self.service = service
        self.coinService = coinService
        self.contactLabelService = contactLabelService

        subscribe(disposeBag, contactLabelService?.stateObservable) { [weak self] _ in
            self?.syncSectionViewItems()
        }

        service.$state
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        sync(state: service.state)
        syncSectionViewItems()
    }

    private func sync(state: CexWithdrawConfirmService.State) {
        switch state {
        case .idle: withdrawing = false
        case .loading: withdrawing = true
        }
    }

    private func syncSectionViewItems() {
        var sectionViewItems: [SectionViewItem] = [
            SectionViewItem(viewItems: mainViewItems()),
        ]

        if let network = service.network {
            sectionViewItems.append(
                SectionViewItem(viewItems: [
                    .value(title: "cex_withdraw_confirm.network".localized, value: network.networkName, type: .regular),
                ])
            )
        }

        let feeData = coinService.amountData(value: service.fee, sign: .plus)
        sectionViewItems.append(
            SectionViewItem(viewItems: [
                .feeValue(
                    title: "cex_withdraw.fee".localized,
                    coinAmount: ValueFormatter.instance.formatFull(coinValue: feeData.coinValue) ?? "n/a".localized,
                    currencyAmount: feeData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) }
                ),
            ])
        )

        self.sectionViewItems = sectionViewItems
    }

    private func mainViewItems() -> [ViewItem] {
        let contactData = contactLabelService?.contactData(for: service.address)
        let amountData = coinService.amountData(value: service.amount, sign: .plus)

        var viewItems: [ViewItem] = [
            .amount(
                title: "cex_withdraw_confirm.you_withdraw".localized,
                iconUrl: service.cexAsset.coin?.imageUrl,
                iconPlaceholderImageName: "placeholder_circle_32",
                coinAmount: ValueFormatter.instance.formatFull(coinValue: amountData.coinValue) ?? "n/a".localized,
                currencyAmount: amountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
                type: .neutral
            ),
            .address(
                title: "send.confirmation.to".localized,
                value: service.address,
                contactAddress: contactData?.contactAddress,
                statSection: .addressTo
            ),
        ]

        if let contactName = contactData?.name {
            viewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
        }

        return viewItems
    }
}

extension CexWithdrawConfirmViewModel {
    var confirmWithdrawPublisher: AnyPublisher<Any, Never> {
        service.confirmWithdrawPublisher
    }

    var errorPublisher: AnyPublisher<String, Never> {
        service.errorPublisher.map(\.smartDescription).eraseToAnyPublisher()
    }

    func onTapWithdraw() {
        service.withdraw()
    }
}

extension CexWithdrawConfirmViewModel {
    struct SectionViewItem {
        let viewItems: [ViewItem]
    }

    enum ViewItem {
        case amount(title: String, iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType)
        case address(title: String, value: String, contactAddress: ContactAddress?, statSection: StatSection)
        case value(title: String, value: String, type: ValueType)
        case feeValue(title: String, coinAmount: String, currencyAmount: String?)
    }
}
