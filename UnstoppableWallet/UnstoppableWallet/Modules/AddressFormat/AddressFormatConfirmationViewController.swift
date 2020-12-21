import UIKit
import ActionSheet
import ThemeKit

protocol IAddressFormatConfirmationDelegate: AnyObject {
    func onConfirm()
}

class AddressFormatConfirmationViewController: ThemeActionSheetController {
    private let coinTypeTitle: String
    private let settingName: String
    private weak var delegate: IAddressFormatConfirmationDelegate?

    private let titleView = BottomSheetTitleView()
    private let descriptionView = HighlightedDescriptionView()
    private let confirmButton = ThemeButton()

    init(coinTypeTitle: String, settingName: String, delegate: IAddressFormatConfirmationDelegate) {
        self.settingName = settingName
        self.coinTypeTitle = coinTypeTitle
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

        titleView.bind(
                title: "blockchain_settings.change_alert.title".localized,
                subtitle: settingName,
                image: UIImage(named: "warning_2_24")?.tinted(with: .themeJacob)
        )
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin3x)
        }

        descriptionView.bind(text: "blockchain_settings.change_alert.content".localized(coinTypeTitle, coinTypeTitle))

        view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        confirmButton.apply(style: .primaryYellow)
        confirmButton.addTarget(self, action: #selector(onTapConfirm), for: .touchUpInside)
        confirmButton.setTitle("blockchain_settings.change_alert.action_button_text".localized(settingName), for: .normal)
    }

    @objc private func onTapConfirm() {
        delegate?.onConfirm()
        dismiss(animated: true)
    }

}
