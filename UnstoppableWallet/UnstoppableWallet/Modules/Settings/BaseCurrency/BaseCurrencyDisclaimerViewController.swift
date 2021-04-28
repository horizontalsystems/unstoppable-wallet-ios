import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class BaseCurrencyDisclaimerViewController: ThemeActionSheetController {
    private let titleView = BottomSheetCenteredTitleView()
    private let descriptionView = HighlightedDescriptionView()
    private let button = ThemeButton()

    private let onAccept: () -> ()

    init(codes: String, onAccept: @escaping () -> ()) {
        self.onAccept = onAccept

        super.init()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.icon = UIImage(named: "warning_2_24")
        titleView.iconTintColor = .themeJacob
        titleView.text = "settings.base_currency.disclaimer".localized

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
        }

        descriptionView.text = "settings.base_currency.disclaimer.description".localized(codes)

        view.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin16 + CGFloat.margin12)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        button.apply(style: .primaryYellow)
        button.setTitle("settings.base_currency.disclaimer.i_understand".localized, for: .normal)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        dismiss(animated: true) { [weak self] in
            self?.onAccept()
        }
    }

}
