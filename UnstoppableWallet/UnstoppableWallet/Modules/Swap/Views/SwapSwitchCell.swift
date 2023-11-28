import ComponentKit
import HUD
import RxSwift
import ThemeKit
import UIKit

class SwapSwitchCell: UITableViewCell {
    let cellHeight: CGFloat = 24

    private let spinner = HUDActivityView.create(with: .medium24)
    private let switchButton = UIButton()

    var onSwitch: (() -> Void)?

    override public init(style _: UITableViewCell.CellStyle, reuseIdentifier _: String?) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        spinner.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        spinner.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        spinner.isHidden = false

        contentView.addSubview(switchButton)
        switchButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        switchButton.setImage(UIImage(named: "arrow_medium_2_swap_24")?.withTintColor(.themeGray), for: .normal)
        switchButton.addTarget(self, action: #selector(onTapSwitch), for: .touchUpInside)
        switchButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        switchButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSwitch() {
        onSwitch?()
    }

    func set(loading: Bool) {
        spinner.isHidden = !loading
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }
}
