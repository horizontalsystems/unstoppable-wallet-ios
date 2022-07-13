import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class PrivateKeyCopyConfirmationViewController: ThemeActionSheetController {
    private let privateKey: String

    init(privateKey: String) {
        self.privateKey = privateKey

        super.init()

        let titleView = BottomSheetTitleView()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.title = "private_key_copying.title".localized
        titleView.image = UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        let descriptionView = HighlightedDescriptionView()

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom)
        }

        descriptionView.text = "private_key_copying.description".localized

        let okButton = ThemeButton()

        view.addSubview(okButton)
        okButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        okButton.apply(style: .primaryYellow)
        okButton.setTitle("button.ok".localized, for: .normal)
        okButton.addTarget(self, action: #selector(onTapOk), for: .touchUpInside)

        let riskButton = ThemeButton()

        view.addSubview(riskButton)
        riskButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(okButton.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        riskButton.apply(style: .primaryTransparent)
        riskButton.setTitle("private_key_copying.i_will_risk_it".localized, for: .normal)
        riskButton.addTarget(self, action: #selector(onTapRisk), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapOk() {
        dismiss(animated: true)
    }

    @objc private func onTapRisk() {
        UIPasteboard.general.setValue(privateKey, forPasteboardType: "public.plain-text")
        dismiss(animated: true) {
            HudHelper.instance.show(banner: .copied)
        }
    }

}
