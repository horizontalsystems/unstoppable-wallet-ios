import Combine

class TermsViewModel: ObservableObject {
    private let termsManager = Core.shared.termsManager
    private var cancellables = Set<AnyCancellable>()

    @Published var acceptedTermIds: Set<String> = []
    @Published var allTermsAccepted: Bool = false

    var terms: [TermsManager.Term] {
        TermsManager.TermsConfiguration.current.terms
    }

    init() {
        termsManager.$state
            .sink { [weak self] state in
                self?.sync(state: state)
            }
            .store(in: &cancellables)

        sync()
    }

    private func sync(state: TermsManager.TermsState? = nil) {
        let state = state ?? termsManager.state

        acceptedTermIds = state.acceptedTermIds
        allTermsAccepted = state.allAccepted
    }
}

extension TermsViewModel {
    func isTermAccepted(_ term: TermsManager.Term) -> Bool {
        acceptedTermIds.contains(term.id)
    }

    func setTermsAccepted() {
        termsManager.setTermsAccepted()
    }
}
