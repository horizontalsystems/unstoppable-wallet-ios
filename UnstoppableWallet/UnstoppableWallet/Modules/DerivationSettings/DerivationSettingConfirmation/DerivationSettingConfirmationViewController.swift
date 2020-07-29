import UIKit
import ActionSheet
import ThemeKit

class DerivationSettingConfirmationViewController: ThemeActionSheetController {
    private let delegate: IDerivationSettingConfirmationViewDelegate

    private let titleView = BottomSheetTitleView()
    private let descriptionView = HighlightedDescriptionView()
    private let confirmButton = ThemeButton()

    init(delegate: IDerivationSettingConfirmationViewDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin3x)
        }

        view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        confirmButton.apply(style: .primaryYellow)
        confirmButton.addTarget(self, action: #selector(_onTapConfirm), for: .touchUpInside)

        delegate.onLoad()
    }

    @objc private func _onTapConfirm() {
        delegate.onTapConfirm()
    }

}

extension DerivationSettingConfirmationViewController: IDerivationSettingConfirmationView {

    func set(coinTitle: String, settingTitle: String) {
        titleView.bind(
                title: "blockchain_settings.change_alert.title".localized,
                subtitle: settingTitle,
                image: UIImage(named: "Attention Icon")
        )

        descriptionView.bind(text: "blockchain_settings.change_alert.content".localized(coinTitle, coinTitle))
        confirmButton.setTitle("blockchain_settings.change_alert.action_button_text".localized(settingTitle), for: .normal)
    }

}
