import Combine
import RxSwift

class UnspentOutputsViewModel {
    private let sendInfoService: ISendInfoValueService
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var item = UnspentOutputsItem(selected: 0, all: 0)
    @Published private(set) var isCustom = false

    init(sendInfoService: ISendInfoValueService) {
        self.sendInfoService = sendInfoService

        subscribe(disposeBag, sendInfoService.sendInfoStateObservable) { [weak self] in self?.sync(sendInfo: $0) }
        sendInfoService.customOutputsUpdatedPublisher
            .sink { [weak self] in
                self?.syncCustom()
            }.store(in: &cancellables)
    }

    private func sync(sendInfo: DataStatus<SendInfo>) {
        var selectedOutputs = sendInfoService.customOutputs?.count
        switch sendInfo {
        case .loading, .failed: ()
        case let .completed(info):
            selectedOutputs = info.unspentOutputs.count
        }

        item = .init(
            selected: selectedOutputs ?? 0,
            all: sendInfoService.unspentOutputs.count
        )
    }

    private func syncCustom() {
        isCustom = sendInfoService.customOutputs != nil
    }
}

extension UnspentOutputsViewModel {
    struct UnspentOutputsItem {
        let selected: Int
        let all: Int
    }
}
