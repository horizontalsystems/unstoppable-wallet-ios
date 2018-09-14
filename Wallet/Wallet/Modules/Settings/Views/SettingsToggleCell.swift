import UIKit
import SnapKit
import RxSwift
import RxCocoa

class SettingsToggleCell: SettingsCell {
    var toggleView = UISwitch()
    var onToggle: ((Bool) -> ())?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        toggleView.tintColor = SettingsTheme.switchTintColor
        toggleView.addTarget(self, action: #selector(_onToggle), for: .touchUpInside)
        contentView.addSubview(toggleView)
        toggleView.snp.makeConstraints { maker in
            maker.trailing.equalTo(self.disclosureImageView.snp.leading).offset(-SettingsTheme.cellBigMargin)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(titleIcon: UIImage?, title: String, isOn: Bool, showDisclosure: Bool, last: Bool = false, onToggle: ((Bool) -> ())? = nil) {
        super.bind(titleIcon: titleIcon, title: title, showDisclosure: showDisclosure, last: last)
        self.onToggle = onToggle
        toggleView.isOn = isOn
    }

    override func bind(titleIcon: UIImage?, title: String, showDisclosure: Bool, last: Bool = false) {
        fatalError("use bind with toggle")
    }

    @objc func _onToggle() {
        onToggle?(toggleView.isOn)
    }

}
