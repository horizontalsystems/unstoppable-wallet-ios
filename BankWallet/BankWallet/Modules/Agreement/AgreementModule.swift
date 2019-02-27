protocol IAgreementView: class {
}

protocol IAgreementViewDelegate {
    func didTapConfirm()
}

protocol IAgreementInteractor {
    func setConfirmed()
}

protocol IAgreementInteractorDelegate: class {
}

protocol IAgreementRouter {
    func dismissWithSuccess()
}
