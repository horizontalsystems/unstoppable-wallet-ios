import RxCocoa
import RxRelay
import RxSwift

class AddMoneroNodeViewModel {
    private let service: AddMoneroNodeService
    private let disposeBag = DisposeBag()

    private let urlCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let finishRelay = PublishRelay<Void>()

    init(service: AddMoneroNodeService) {
        self.service = service
    }
}

extension AddMoneroNodeViewModel {
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

    func onChange(login: String?) {
        service.set(login: login ?? "")
    }

    func onChange(password: String?) {
        service.set(password: password ?? "")
    }

    func onTapAdd() {
        do {
            try service.save()
            stat(page: .blockchainSettingsMoneroAdd, event: .addMoneroNode(chainUid: service.blockchainType.uid))
            finishRelay.accept(())
        } catch AddMoneroNodeService.UrlError.alreadyExists {
            urlCautionRelay.accept(Caution(text: "add_monero_node.warning.url_exists".localized, type: .warning))
        } catch AddMoneroNodeService.UrlError.invalid {
            urlCautionRelay.accept(Caution(text: "add_monero_node.error.invalid_url".localized, type: .error))
        } catch {}
    }
}
