import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class BaseCurrencyDisclaimerViewController: ThemeActionSheetController {
    private let onAccept: () -> ()

    init(codes: String, onAccept: @escaping () -> ()) {
        self.onAccept = onAccept

        super.init()

        let titleView = BottomSheetTitleView()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.title = "settings.base_currency.disclaimer".localized
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

        descriptionView.text = "settings.base_currency.disclaimer.description".localized(codes)

        let setButton = ThemeButton()

        view.addSubview(setButton)
        setButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        setButton.apply(style: .primaryYellow)
        setButton.setTitle("settings.base_currency.disclaimer.set".localized, for: .normal)
        setButton.addTarget(self, action: #selector(onTapSet), for: .touchUpInside)

        let cancelButton = ThemeButton()

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(setButton.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        cancelButton.apply(style: .primaryTransparent)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSet() {
        dismiss(animated: true) { [weak self] in
            self?.onAccept()
        }
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

}
