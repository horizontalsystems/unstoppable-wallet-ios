import UIKit
import ThemeKit

class PrivacyCell: ThemeCell {
    private let leftView = UIImageView()
    private let middleView = UILabel()
    private let rightView = UILabel()
    private let disclosureView = UIImageView(image: UIImage(named: "Privacy Drop Down"))

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(24)
        }

        contentView.addSubview(middleView)
        middleView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(leftView.snp.trailing).offset(CGFloat.margin4x)
        }

        middleView.font = .body
        middleView.textColor = .themeOz

        contentView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(middleView.snp.trailing)
        }

        rightView.font = .subhead1
        rightView.textColor = .themeLeah
        rightView.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightView.setContentHuggingPriority(.required, for: .horizontal)

        contentView.addSubview(disclosureView)
        disclosureView.snp.makeConstraints { maker in
            maker.leading.equalTo(rightView.snp.trailing).offset(CGFloat.margin2x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.size.equalTo(12)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func bind(image: UIImage?, title: String?, value: String?, showDisclosure: Bool, last: Bool = false) {
        super.bind(last: last)

        leftView.snp.updateConstraints { maker in
            maker.size.equalTo(image == nil ? 0 : 24)
        }
        middleView.snp.updateConstraints { maker in
            maker.leading.equalTo(leftView.snp.trailing).offset(image == nil ? 0 : CGFloat.margin4x)
        }

        disclosureView.snp.updateConstraints { maker in
            maker.leading.equalTo(rightView.snp.trailing).offset(showDisclosure ? CGFloat.margin2x : 0)
            maker.size.equalTo(showDisclosure ? 12 : 0)
        }

        selectionStyle = showDisclosure ? .default : .none

        leftView.image = image
        middleView.text = title
        rightView.text = value
    }

}
