import UIKit
import SnapKit

class RightLabelCell: TitleCell {
    var rightLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        rightLabel.textColor = .themeGray
        contentView.addSubview(rightLabel)
        rightLabel.snp.makeConstraints { maker in
            maker.trailing.equalTo(disclosureImageView.snp.leading).offset(-CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(titleIcon: UIImage?, title: String, rightText: String?, showDisclosure: Bool, last: Bool = false) {
        super.bind(titleIcon: titleIcon, title: title, showDisclosure: showDisclosure, last: last)
        rightLabel.text = rightText
    }

}
