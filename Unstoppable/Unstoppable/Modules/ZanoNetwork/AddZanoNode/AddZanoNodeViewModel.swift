import RxCocoa
import RxRelay
import RxSwift

class AddZanoNodeViewModel {
    private let service: AddZanoNodeService
    private let disposeBag = DisposeBag()

    private let urlCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let finishRelay = PublishRelay<Void>()

    init(service: AddZanoNodeService) {
        self.service = service
    }
}

extension AddZanoNodeViewModel {
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

    func onTapAdd() {
        do {
            try service.save()
            finishRelay.accept(())
        } catch AddZanoNodeService.UrlError.alreadyExists {
            urlCautionRelay.accept(Caution(text: "add_zano_node.warning.url_exists".localized, type: .warning))
        } catch AddZanoNodeService.UrlError.invalid {
            urlCautionRelay.accept(Caution(text: "add_zano_node.error.invalid_url".localized, type: .error))
        } catch {}
    }
}
