import RxSwift
import RxCocoa

class SendSettingsViewModel {
    let service: SendSettingsService

    private let disposeBag = DisposeBag()

    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)

    init(service: SendSettingsService) {
        self.service = service

        subscribe(disposeBag, service.statusObservable) { [weak self] in self?.sync(transactionStatus: $0) }
        sync(transactionStatus: service.status)
    }

    private func sync(transactionStatus: DataStatus<Void>) {
        let cautions: [TitledCaution]

        switch transactionStatus {
        case .loading:
            cautions = []
        case .failed(let error):
            cautions = []
        case .completed(let fallibleTransaction):
            cautions = []
        }

        cautionRelay.accept(cautions.first)
    }

}

extension SendSettingsViewModel {

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }

}
