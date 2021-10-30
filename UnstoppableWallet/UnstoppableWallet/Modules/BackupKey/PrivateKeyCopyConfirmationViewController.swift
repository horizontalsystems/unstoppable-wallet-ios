import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class PrivateKeyCopyConfirmationViewController: ThemeActionSheetController {
    private let titleView = BottomSheetTitleView()
    private let descriptionView = HighlightedDescriptionView()
    private let copyButton = ThemeButton()

    private let privateKey: String

    init(privateKey: String) {
        self.privateKey = privateKey

        super.init()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                title: "private_key_copying.title".localized,
                subtitle: "private_key_copying.subtitle".localized,
                image: UIImage(named: "warning_2_24"),
                tintColor: .themeJacob
        )
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin3x)
        }

        descriptionView.text = "private_key_copying.description".localized

        view.addSubview(copyButton)
        copyButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        copyButton.apply(style: .primaryRed)
        copyButton.setTitle("private_key_copying.copy_button".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapCopy() {
        UIPasteboard.general.setValue(privateKey, forPasteboardType: "public.plain-text")
        dismiss(animated: true) {
            HudHelper.instance.showSuccess(title: "alert.copied".localized)
        }
    }

}
