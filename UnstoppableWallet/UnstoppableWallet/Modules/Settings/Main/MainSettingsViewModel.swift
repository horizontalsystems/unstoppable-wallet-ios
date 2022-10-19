import WalletConnectV1
import RxSwift
import RxRelay
import RxCocoa
import ThemeKit

class MainSettingsViewModel {
    private let service: MainSettingsService
    private let disposeBag = DisposeBag()

    private let manageWalletsAlertRelay: BehaviorRelay<Bool>
    private let securityCenterAlertRelay: BehaviorRelay<Bool>
    private let walletConnectSessionCountRelay: BehaviorRelay<String?>
    private let baseCurrencyRelay: BehaviorRelay<String>
    private let aboutAlertRelay: BehaviorRelay<Bool>
    private let openWalletConnectRelay = PublishRelay<WalletConnectOpenMode>()
    private let openLinkRelay = PublishRelay<String>()

    init(service: MainSettingsService) {
        self.service = service

        manageWalletsAlertRelay = BehaviorRelay(value: !service.allBackedUp)
        securityCenterAlertRelay = BehaviorRelay(value: !service.isPinSet)
        walletConnectSessionCountRelay = BehaviorRelay(value: Self.convert(walletConnectSessionCount: service.walletConnectSessionCount))
        baseCurrencyRelay = BehaviorRelay(value: service.baseCurrency.code)
        aboutAlertRelay = BehaviorRelay(value: !service.termsAccepted)

        service.allBackedUpObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] allBackedUp in
                    self?.manageWalletsAlertRelay.accept(!allBackedUp)
                })
                .disposed(by: disposeBag)

        service.isPinSetObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] isPinSet in
                    self?.securityCenterAlertRelay.accept(!isPinSet)
                })
                .disposed(by: disposeBag)

        service.walletConnectSessionCountObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] count in
                    self?.walletConnectSessionCountRelay.accept(Self.convert(walletConnectSessionCount: count))
                })
                .disposed(by: disposeBag)

        service.baseCurrencyObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] currency in
                    self?.baseCurrencyRelay.accept(currency.code)
                })
                .disposed(by: disposeBag)

        service.termsAcceptedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] accepted in
                    self?.aboutAlertRelay.accept(!accepted)
                })
                .disposed(by: disposeBag)
    }

    private static func convert(walletConnectSessionCount: Int) -> String? {
        walletConnectSessionCount > 0 ? "\(walletConnectSessionCount)" : nil
    }

}

extension MainSettingsViewModel {

    var openWalletConnectSignal: Signal<WalletConnectOpenMode> {
        openWalletConnectRelay.asSignal()
    }

    var openLinkSignal: Signal<String> {
        openLinkRelay.asSignal()
    }

    var manageWalletsAlertDriver: Driver<Bool> {
        manageWalletsAlertRelay.asDriver()
    }

    var securityCenterAlertDriver: Driver<Bool> {
        securityCenterAlertRelay.asDriver()
    }

    var walletConnectSessionCountDriver: Driver<String?> {
        walletConnectSessionCountRelay.asDriver()
    }

    var baseCurrencyDriver: Driver<String> {
        baseCurrencyRelay.asDriver()
    }

    var aboutAlertDriver: Driver<Bool> {
        aboutAlertRelay.asDriver()
    }

    var currentLanguage: String? {
        service.currentLanguageDisplayName
    }

    var appVersion: String {
        service.appVersion
    }

    func onTapWalletConnect() {
        guard let activeAccount = service.activeAccount else {
            openWalletConnectRelay.accept(.noAccount)
            return
        }

        openWalletConnectRelay.accept(activeAccount.type.supportsWalletConnect ? .list : .nonSupportedAccountType(accountTypeDescription: activeAccount.type.description))
    }

    func onTapCompanyLink() {
        openLinkRelay.accept(service.companyWebPageLink)
    }

}

extension MainSettingsViewModel {

    enum WalletConnectOpenMode {
        case list
        case noAccount
        case nonSupportedAccountType(accountTypeDescription: String)
    }

}
