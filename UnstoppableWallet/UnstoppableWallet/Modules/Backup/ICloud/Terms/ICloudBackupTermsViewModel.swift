import Combine
import HsExtensions

class ICloudBackupTermsViewModel {
    private var cancellables = Set<AnyCancellable>()

    private let service: ICloudBackupTermsService
    @Published public var viewItems = [ViewItem]()
    @Published public var buttonEnabled: Bool = false

    private let showCloudNotAvailableSubject = PassthroughSubject<Void, Never>()
    private let showModuleSubject = PassthroughSubject<Void, Never>()

    init(service: ICloudBackupTermsService) {
        self.service = service

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: ICloudBackupTermsService.State) {
        guard case let .selectedTerms(checkedIndices) = state else {
            return
        }

        viewItems = (0..<service.termCount).map { index in
            ViewItem(text: "backup.cloud.terms.item.\(index + 1)".localized, checked: checkedIndices.contains(index))
        }

        buttonEnabled = checkedIndices.count == service.termCount
    }

}

extension ICloudBackupTermsViewModel {

    var account: Account {
        service.account
    }

    var showCloudNotAvailablePublisher: AnyPublisher<Void, Never> {
        showCloudNotAvailableSubject.eraseToAnyPublisher()
    }

    var showModulePublisher: AnyPublisher<Void, Never> {
        showModuleSubject.eraseToAnyPublisher()
    }

    func onToggle(index: Int) {
        service.toggleTerm(at: index)
    }

    func onContinue() {
        if service.cloudIsAvailable {
            showModuleSubject.send(())
        } else {
            showCloudNotAvailableSubject.send(())
        }
    }

}

extension ICloudBackupTermsViewModel {

    struct ViewItem: Equatable {
        let text: String
        let checked: Bool

        static func ==(lhs: ViewItem, rhs: ViewItem) -> Bool {
            lhs.text == rhs.text &&
            lhs.checked == rhs.checked
        }
    }

}
