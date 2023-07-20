import RxRelay
import RxSwift
import RxCocoa

class SimpleActivateViewModel {
    private let disposeBag = DisposeBag()
    private let service: ISimpleActivateService
    private let config: ViewItem

    private let featureEnabledRelay = BehaviorRelay<Bool>(value: false)

    init(service: ISimpleActivateService, config: ViewItem) {
        self.service = service
        self.config = config

        subscribe(disposeBag, service.activatedChangedObservable) { [weak self] in self?.sync(featureEnabled: $0) }
    }

    private func sync(featureEnabled: Bool) {
        featureEnabledRelay.accept(featureEnabled)
    }

}
extension SimpleActivateViewModel {

    var viewItem: ViewItem {
        config
    }

    var featureEnabled: Bool {
        service.activated
    }

    var featureEnabledDriver: Driver<Bool> {
        featureEnabledRelay.asDriver()
    }

    func onToggle() {
        service.toggle()
    }

}

extension SimpleActivateViewModel {

    struct ViewItem {
        static var bitcoinHodling = ViewItem(
                title: "settings.bitcoin_hodling.title".localized,
                activateTitle: "settings.bitcoin_hodling.lock_time".localized,
                activateDescription: "settings.bitcoin_hodling.description".localized(AppConfig.appName, AppConfig.appName)
        )

        let title: String
        let activateTitle: String
        let activateDescription: String
    }

}
