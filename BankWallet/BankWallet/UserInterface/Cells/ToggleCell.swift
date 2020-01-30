import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ThemeKit

class ToggleCell: TitleCell {
    var toggleView = UISwitch()
    var onToggle: ((Bool) -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.addSubview(toggleView)
        toggleView.snp.makeConstraints { maker in
            maker.trailing.equalTo(disclosureImageView.snp.leading).inset(1.6)
            maker.centerY.equalToSuperview()
        }

        toggleView.tintColor = .themeSteel20
        toggleView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(titleIcon: UIImage? = nil, title: String, isOn: Bool, last: Bool = false, onToggle: ((Bool) -> ())? = nil) {
        super.bind(titleIcon: titleIcon, title: title, last: last)
        self.onToggle = onToggle
        toggleView.isOn = isOn
    }

    @objc func switchChanged() {
        onToggle?(toggleView.isOn)
    }

}
