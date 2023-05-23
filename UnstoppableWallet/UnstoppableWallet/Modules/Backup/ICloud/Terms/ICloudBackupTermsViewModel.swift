import Combine
import HsExtensions

class ICloudBackupTermsViewModel {
    private var cancellables = Set<AnyCancellable>()

    private let service: ICloudBackupTermsService
    @Published public var viewItems = [ViewItem]()
    @Published public var buttonEnabled: Bool = false

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

    func onToggle(index: Int) {
        service.toggleTerm(at: index)
    }

    func onTapAgree() {
//        service.setTermsAccepted()
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
