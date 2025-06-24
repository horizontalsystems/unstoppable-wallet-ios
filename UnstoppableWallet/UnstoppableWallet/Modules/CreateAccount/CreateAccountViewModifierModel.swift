import Combine

class CreateAccountViewModifierModel: ObservableObject {
    private let termsManager = Core.shared.termsManager

    @Published var termsPresented = false
    @Published var createPresented = false

    func handle() {
        if termsManager.termsAccepted {
            createPresented = true
        } else {
            termsPresented = true
        }
    }
}
