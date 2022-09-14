class TermsService {
    private let termsManager: TermsManager
    let termsAccepted: Bool

    init(termsManager: TermsManager) {
        self.termsManager = termsManager

        termsAccepted = termsManager.termsAccepted
    }

}

extension TermsService {

    func setTermsAccepted() {
        termsManager.setTermsAccepted()
    }

}
