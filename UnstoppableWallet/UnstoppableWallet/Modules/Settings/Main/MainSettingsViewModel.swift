import WalletConnect
import RxSwift
import RxRelay
import RxCocoa

class MainSettingsViewModel {
    private let service: MainSettingsService
    private let disposeBag = DisposeBag()

    private let manageWalletsAlertRelay: BehaviorRelay<Bool>
    private let securityCenterAlertRelay: BehaviorRelay<Bool>
    private let walletConnectSessionCountRelay: BehaviorRelay<String?>
    private let baseCurrencyRelay: BehaviorRelay<String>
    private let aboutAlertRelay: BehaviorRelay<Bool>
    private let openLinkRelay = PublishRelay<URL>()

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

    var openLinkSignal: Signal<URL> {
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

    var lightMode: Bool {
        service.lightMode
    }

    var telegramAccount: String {
        service.telegramAccount
    }

    var twitterAccount: String {
        service.twitterAccount
    }

    var redditAccount: String {
        service.redditAccount
    }

    var appVersion: String {
        service.appVersion
    }

    func onSwitch(lightMode: Bool) {
        service.lightMode = lightMode
    }

    func onTapCompanyLink() {
        guard let url = URL(string: service.companyWebPageLink) else {
            return
        }

        openLinkRelay.accept(url)
    }

}
