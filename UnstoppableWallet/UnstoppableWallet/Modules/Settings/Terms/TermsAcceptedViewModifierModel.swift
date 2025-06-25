import Combine

class TermsAcceptedViewModifierModel: ObservableObject {
    private let termsManager = Core.shared.termsManager

    @Published var termsPresented = false
    @Published var modulePresented = false

    func handle() {
        if termsManager.termsAccepted {
            modulePresented = true
        } else {
            termsPresented = true
        }
    }
}
