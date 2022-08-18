import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class CopyConfirmationViewController: ThemeActionSheetController {
    private let value: String

    init(value: String) {
        self.value = value

        super.init()

        let titleView = BottomSheetTitleView()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.title = "copy_warning.title".localized
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

        descriptionView.text = "copy_warning.description".localized

        let okButton = PrimaryButton()

        view.addSubview(okButton)
        okButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin24)
        }

        okButton.set(style: .yellow)
        okButton.setTitle("button.ok".localized, for: .normal)
        okButton.addTarget(self, action: #selector(onTapOk), for: .touchUpInside)

        let riskButton = PrimaryButton()

        view.addSubview(riskButton)
        riskButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(okButton.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        riskButton.set(style: .transparent)
        riskButton.setTitle("copy_warning.i_will_risk_it".localized, for: .normal)
        riskButton.addTarget(self, action: #selector(onTapRisk), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapOk() {
        dismiss(animated: true)
    }

    @objc private func onTapRisk() {
        UIPasteboard.general.string = value

        dismiss(animated: true) {
            HudHelper.instance.show(banner: .copied)
        }
    }

}
