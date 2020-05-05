protocol IPrivacyInfoRouter {
    func close()
}

protocol IPrivacyInfoView: class {
}

protocol IPrivacyInfoViewDelegate {
    func onClose()
}
