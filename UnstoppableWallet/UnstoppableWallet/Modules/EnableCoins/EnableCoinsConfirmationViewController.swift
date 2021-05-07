import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class EnableCoinsConfirmationViewController: ThemeActionSheetController {
    private let titleView = BottomSheetTitleView()
    private let descriptionView = HighlightedDescriptionView()
    private let enableButton = ThemeButton()

    private let onEnable: () -> ()

    init(tokenType: String, onEnable: @escaping () -> ()) {
        self.onEnable = onEnable

        super.init()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                title: "enable_coins.title".localized,
                subtitle: tokenType,
                image: UIImage(named: tokenType.lowercased())
        )
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin3x)
        }

        descriptionView.text = "enable_coins.description".localized(tokenType)

        view.addSubview(enableButton)
        enableButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        enableButton.apply(style: .primaryYellow)
        enableButton.setTitle("enable_coins.enable_button".localized, for: .normal)
        enableButton.addTarget(self, action: #selector(onTapEnable), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapEnable() {
        dismiss(animated: true) { [weak self] in
            self?.onEnable()
        }
    }

}
