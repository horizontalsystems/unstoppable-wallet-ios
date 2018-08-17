import UIKit
import SnapKit

class SettingsRightImageCell: SettingsCell {
    var rightImageView = UIImageView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(rightImageView)
        rightImageView.snp.makeConstraints { maker in
            maker.trailing.equalTo(self.disclosureImageView.snp.leading).offset(-SettingsTheme.cellBigMargin)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(titleIcon: UIImage?, title: String, rightImage: UIImage?, showDisclosure: Bool, last: Bool = false) {
        super.bind(titleIcon: titleIcon, title: title, showDisclosure: showDisclosure, last: last)
        rightImageView.image = rightImage
    }

    override func bind(titleIcon: UIImage?, title: String, showDisclosure: Bool, last: Bool = false) {
        fatalError("use bind with right image")
    }

}
