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
    private let walletConnectCountRelay: BehaviorRelay<(highlighted: Bool,text: String)?>
    private let baseCurrencyRelay: BehaviorRelay<String>
    private let aboutAlertRelay: BehaviorRelay<Bool>
    private let openWalletConnectRelay = PublishRelay<WalletConnectOpenMode>()
    private let openLinkRelay = PublishRelay<String>()

    init(service: MainSettingsService) {
        self.service = service

        manageWalletsAlertRelay = BehaviorRelay(value: !service.noWalletRequiredActions)
        securityCenterAlertRelay = BehaviorRelay(value: !service.isPinSet)
        walletConnectCountRelay = BehaviorRelay(value: Self.convert(walletConnectSessionCount: service.walletConnectSessionCount, walletConnectPendingRequestCount: service.walletConnectPendingRequestCount))
        baseCurrencyRelay = BehaviorRelay(value: service.baseCurrency.code)
        aboutAlertRelay = BehaviorRelay(value: !service.termsAccepted)

        service.noWalletRequiredActionsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] noWalletRequiredActions in
                    self?.manageWalletsAlertRelay.accept(!noWalletRequiredActions)
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
                    self?.walletConnectCountRelay.accept(Self.convert(walletConnectSessionCount: count, walletConnectPendingRequestCount: self?.service.walletConnectPendingRequestCount ?? 0))
                })
                .disposed(by: disposeBag)

        service.walletConnectPendingRequestCountObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] count in
                    self?.walletConnectCountRelay.accept(Self.convert(walletConnectSessionCount: self?.service.walletConnectSessionCount ?? 0, walletConnectPendingRequestCount: count))
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

    private static func convert(walletConnectSessionCount: Int, walletConnectPendingRequestCount: Int) -> (highlighted: Bool,text: String)? {
        if walletConnectPendingRequestCount != 0 {
            return (highlighted: true, text: "\(walletConnectPendingRequestCount)")
        }
        return walletConnectSessionCount > 0 ? (highlighted: false, text: "\(walletConnectSessionCount)") : nil
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

    var walletConnectCountDriver: Driver<(highlighted: Bool,text: String)?> {
        walletConnectCountRelay.asDriver()
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
            openWalletConnectRelay.accept(.errorDialog(error: .noAccount))
            return
        }

        if !activeAccount.type.supportsWalletConnect {
            openWalletConnectRelay.accept(.errorDialog(error: .nonSupportedAccountType(accountTypeDescription: activeAccount.type.description)))
            return
        }

        openWalletConnectRelay.accept(activeAccount.backedUp ? .list : .errorDialog(error: .unbackupedAccount(account: activeAccount)))
    }

    func onTapCompanyLink() {
        openLinkRelay.accept(service.companyWebPageLink)
    }

}

extension MainSettingsViewModel {

    enum WalletConnectOpenMode {
        case list
        case errorDialog(error: WalletConnectV2AppShowView.WalletConnectOpenError)
    }

}
