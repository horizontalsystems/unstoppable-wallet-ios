import RxSwift
import RxRelay
import RxCocoa

class AboutViewModel {
    private let service: AboutService
    private let disposeBag = DisposeBag()

    private let termsAlertRelay: BehaviorRelay<Bool>
    private let openLinkRelay = PublishRelay<URL>()

    init(service: AboutService) {
        self.service = service

        termsAlertRelay = BehaviorRelay(value: !service.termsAccepted)

        service.termsAcceptedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] accepted in
                    self?.termsAlertRelay.accept(!accepted)
                })
                .disposed(by: disposeBag)
    }

}

extension AboutViewModel {

    var openLinkSignal: Signal<URL> {
        openLinkRelay.asSignal()
    }

    var termsAlertDriver: Driver<Bool> {
        termsAlertRelay.asDriver()
    }

    var appVersion: String {
        service.appVersion
    }

    var appWebPageLink: String {
        service.appWebPageLink
    }

    var contactEmail: String {
        service.contactEmail
    }

    func onTapGithubLink() {
        guard let url = URL(string: service.appGitHubLink) else {
            return
        }

        openLinkRelay.accept(url)
    }

    func onTapWebPageLink() {
        guard let url = URL(string: service.appWebPageLink) else {
            return
        }

        openLinkRelay.accept(url)
    }

    func onTapRateApp() {
        service.rateApp()
    }

}
