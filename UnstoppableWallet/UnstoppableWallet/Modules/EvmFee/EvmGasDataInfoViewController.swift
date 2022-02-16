import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class EvmGasDataInfoViewController: ThemeActionSheetController {
    private let titleView = BottomSheetCenteredTitleView()
    private let button = ThemeButton()

    init(title: String, description: String) {
        super.init()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.icon = UIImage(named: "circle_information_24")
        titleView.iconTintColor = .themeJacob
        titleView.text = title

        let label = UILabel()
        view.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
        }

        label.text = description
        label.numberOfLines = 0
        label.font = .body
        label.textColor = .themeBran


        view.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(label.snp.bottom).offset(CGFloat.margin16 + CGFloat.margin12)
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
        dismiss(animated: true)
    }

}
