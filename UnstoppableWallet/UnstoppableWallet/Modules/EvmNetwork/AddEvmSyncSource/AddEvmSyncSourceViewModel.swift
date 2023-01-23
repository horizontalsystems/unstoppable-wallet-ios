import RxSwift
import RxRelay
import RxCocoa

class AddEvmSyncSourceViewModel {
    private let service: AddEvmSyncSourceService
    private let disposeBag = DisposeBag()

    private let urlCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let finishRelay = PublishRelay<Void>()

    init(service: AddEvmSyncSourceService) {
        self.service = service
    }

}

extension AddEvmSyncSourceViewModel {

    var urlCautionDriver: Driver<Caution?> {
        urlCautionRelay.asDriver()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func onChange(url: String?) {
        service.set(urlString: url ?? "")
        urlCautionRelay.accept(nil)
    }

    func onChange(basicAuth: String?) {
        service.set(basicAuth: basicAuth ?? "")
    }

    func onTapAdd() {
        do {
            try service.save()
            finishRelay.accept(())
        } catch AddEvmSyncSourceService.UrlError.alreadyExists {
            urlCautionRelay.accept(Caution(text: "add_evm_sync_source.warning.url_exists".localized, type: .warning))
        } catch AddEvmSyncSourceService.UrlError.invalid {
            urlCautionRelay.accept(Caution(text: "add_evm_sync_source.error.invalid_url".localized, type: .error))
        } catch {
        }
    }

}
