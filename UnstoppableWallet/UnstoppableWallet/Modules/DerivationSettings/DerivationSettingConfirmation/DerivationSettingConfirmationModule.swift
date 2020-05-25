protocol IDerivationSettingConfirmationView: AnyObject {
    func set(coinTitle: String, settingTitle: String)
}

protocol IDerivationSettingConfirmationViewDelegate {
    func onLoad()
    func onTapConfirm()
}

protocol IDerivationSettingConfirmationRouter {
    func close()
}

protocol IDerivationSettingConfirmationDelegate: AnyObject {
    func onConfirm(setting: DerivationSetting)
}
