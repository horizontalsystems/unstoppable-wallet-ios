import UIKit
import SnapKit
import ThemeKit

class DoubleSpendInfoCell: TitleCell {
    private let button = ThemeButton()

    private var onTap: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = .subhead2
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(disclosureImageView.snp.leading)
        }

        button.apply(style: .secondaryDefault)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTap?()
    }

    func bind(title: String, hash: String?, last: Bool, onTap: (() -> ())? = nil) {
        super.bind(titleIcon: nil, title: title, titleColor: .themeGray, last: last)

        button.setTitle(hash, for: .normal)
        self.onTap = onTap
    }

}
