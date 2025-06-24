import Combine

class TermsViewModelNew: ObservableObject {
    private let termsManager = Core.shared.termsManager

    let termsAccepted: Bool

    init() {
        termsAccepted = termsManager.termsAccepted
    }
}

extension TermsViewModelNew {
    func setTermsAccepted() {
        termsManager.setTermsAccepted()
    }
}
