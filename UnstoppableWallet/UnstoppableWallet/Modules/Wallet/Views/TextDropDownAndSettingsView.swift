import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class TextDropDownAndSettingsView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let dropdownButton = SecondaryButton()
    private let settingsButton = SecondaryCircleButton()

    var onTapDropDown: (() -> ())?
    var onTapSettings: (() -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    init() {
        super.init(reuseIdentifier: "")
        commonInit()
    }

    private func commonInit() {
        addSubview(dropdownButton)
        dropdownButton.snp.makeConstraints { maker in
            maker.leading.centerY.equalToSuperview()
        }

        dropdownButton.set(style: .transparent)
        dropdownButton.set(image: UIImage(named: "arrow_small_down_20"))
        dropdownButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dropdownButton.addTarget(self, action: #selector(onTapDropDownButton), for: .touchUpInside)

        addSubview(settingsButton)
        settingsButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalTo(dropdownButton)
        }

        settingsButton.set(image: UIImage(named: "manage_2_20"))
        settingsButton.addTarget(self, action: #selector(onTapSettingsButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapDropDownButton() {
        onTapDropDown?()
    }

    @objc private func onTapSettingsButton() {
        onTapSettings?()
    }

    func bind(dropdownTitle: String?, settingsHidden: Bool = false) {
        dropdownButton.setTitle(dropdownTitle, for: .normal)
        settingsButton.isHidden = settingsHidden
    }

}
