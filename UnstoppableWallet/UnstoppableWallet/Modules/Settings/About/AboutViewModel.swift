import Foundation
import RxCocoa
import RxRelay
import RxSwift

class AboutViewModel {
    private let service: AboutService
    private let releaseNotesService: ReleaseNotesService
    private let disposeBag = DisposeBag()

    private let termsAlertRelay: BehaviorRelay<Bool>
    private let openLinkRelay = PublishRelay<String>()

    init(service: AboutService, releaseNotesService: ReleaseNotesService) {
        self.service = service
        self.releaseNotesService = releaseNotesService

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
    var openLinkSignal: Signal<String> {
        openLinkRelay.asSignal()
    }

    var termsAlertDriver: Driver<Bool> {
        termsAlertRelay.asDriver()
    }

    var appVersion: String {
        service.appVersion
    }

    var releaseNotesUrl: URL? {
        releaseNotesService.lastVersionUrl
    }

    func onTapGithubLink() {
        openLinkRelay.accept("https://github.com/\(AppConfig.appGitHubAccount)/\(AppConfig.appGitHubRepository)")
    }

    func onTapWebPageLink() {
        openLinkRelay.accept(AppConfig.appWebPageLink)
    }
}
