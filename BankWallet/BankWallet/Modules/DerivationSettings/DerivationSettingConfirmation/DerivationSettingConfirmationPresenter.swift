class DerivationSettingConfirmationPresenter {
    weak var view: IDerivationSettingConfirmationView?
    weak var delegate: IDerivationSettingConfirmationDelegate?

    private let router: IDerivationSettingConfirmationRouter

    private let coinTitle: String
    private let setting: DerivationSetting

    init(coinTitle: String, setting: DerivationSetting, router: IDerivationSettingConfirmationRouter) {
        self.coinTitle = coinTitle
        self.setting = setting
        self.router = router
    }

}

extension DerivationSettingConfirmationPresenter: IDerivationSettingConfirmationViewDelegate {

    func onLoad() {
        view?.set(coinTitle: coinTitle, settingTitle: setting.derivation.rawValue.uppercased())
    }

    func onTapConfirm() {
        delegate?.onConfirm(setting: setting)
        router.close()
    }

}
