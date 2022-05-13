import RxSwift
import RxRelay
import RxCocoa

class SendConfirmationViewModel {
    private let disposeBag = DisposeBag()
    private let service: SendConfirmationService

    private let viewItemRelay = BehaviorRelay<[[ViewItem]]>(value: [])
    private var viewItems = [[ViewItem]]() {
        didSet {
            viewItemRelay.accept(viewItems)
        }
    }

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let sendingRelay = PublishRelay<()>()
    private let sendSuccessRelay = PublishRelay<()>()
    private let sendFailedRelay = PublishRelay<String>()

    init(service: SendConfirmationService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        syncViewItems()
    }

    private func syncViewItems() {
        var primaryViewItems = [ViewItem]()
        var secondaryViewItems = [ViewItem]()

        primaryViewItems.append(.header(title: "send.confirmation.you_send".localized, subtitle: service.coinName))
        service.items.forEach { item in
            switch item {
            case let item as SendConfirmationAmountViewItem:
                if let primary = item.primaryInfo.formattedString {
                    primaryViewItems.append(.amount(
                            primary: primary,
                            secondary: item.secondaryInfo?.formattedString)
                    )
                }
                let title = item.receiver.domain != nil ? "send.confirmation.domain" : "send.confirmation.address"
                primaryViewItems.append(.recipient(
                        title: title.localized,
                        address: item.receiver.title,
                        copyValue: item.receiver.raw)
                )
            case let item as SendConfirmationMemoViewItem:
                primaryViewItems.append(.additional(
                        title: "send.confirmation.memo".localized,
                        value: item.memo)
                )
            case let item as SendConfirmationFeeViewItem:
                let value = [item.primaryInfo.formattedString, item.secondaryInfo?.formattedString]
                        .compactMap { $0 }
                        .joined(separator: " | ")

                secondaryViewItems.append(.fee(
                        title: "send.confirmation.fee".localized, value: value))
            case let item as SendConfirmationLockUntilViewItem:
                primaryViewItems.append(.additional(
                        title: "send.confirmation.time_lock".localized,
                        value: item.lockValue)
                )

            default: ()
            }
        }

        viewItems = [primaryViewItems, secondaryViewItems]
    }

    private func sync(state: SendConfirmationService.State) {
        switch state {
        case .idle:
            sendEnabledRelay.accept(true)
        case .sending:
            sendEnabledRelay.accept(false)
            sendingRelay.accept(())
        case .sent:
            sendEnabledRelay.accept(false)
            sendSuccessRelay.accept(())
        case .failed(let error):
            sendEnabledRelay.accept(true)
            sendFailedRelay.accept(error.smartDescription)
        }
    }

}

extension SendConfirmationViewModel {

    var viewItemDriver: Driver<[[ViewItem]]> {
        viewItemRelay.asDriver()
    }

    var sendEnabledDriver: Driver<Bool> {
        sendEnabledRelay.asDriver()
    }

    var sendingSignal: Signal<()> {
        sendingRelay.asSignal()
    }

    var sendSuccessSignal: Signal<()> {
        sendSuccessRelay.asSignal()
    }

    var sendFailedSignal: Signal<String> {
        sendFailedRelay.asSignal()
    }

    func send() {
        service.send()
    }

}
extension SendConfirmationViewModel {

    enum ViewItem {
        case header(title: String, subtitle: String)
        case amount(primary: String, secondary: String?)
        case recipient(title: String, address: String, copyValue: String)
        case additional(title: String, value: String)
        case fee(title: String, value: String)
    }

}