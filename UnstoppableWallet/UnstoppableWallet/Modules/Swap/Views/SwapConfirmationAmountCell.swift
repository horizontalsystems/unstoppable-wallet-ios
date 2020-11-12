
import UIKit
import SnapKit
import ThemeKit

class SwapConfirmationAmountCell: ThemeCell {
    static let height: CGFloat = 72

    private let topLineView = UIView()
    private let bottomLineView = UIView()

    private let payTitleLabel = UILabel()
    private let payValueLabel = UILabel()

    private let getTitleLabel = UILabel()
    private let getValueLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .themeLawrence
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(topLineView)
        topLineView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        topLineView.backgroundColor = .themeSteel20

        contentView.addSubview(payTitleLabel)
        payTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        payTitleLabel.font = .headline2
        payTitleLabel.textColor = .themeOz

        contentView.addSubview(payValueLabel)
        payValueLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.leading.equalTo(payTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        payValueLabel.font = .subhead1
        payValueLabel.textColor = .themeOz
        payValueLabel.textAlignment = .right

        payTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        payValueLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        contentView.addSubview(getTitleLabel)
        getTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        getTitleLabel.font = .subhead2
        getTitleLabel.textColor = .themeGray

        contentView.addSubview(getValueLabel)
        getValueLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.leading.equalTo(getTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        getValueLabel.font = .subhead2
        getValueLabel.textColor = .themeGray
        getValueLabel.textAlignment = .right

        getTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        getValueLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        contentView.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        bottomLineView.backgroundColor = .themeSteel20

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(payTitle: String?, payValue: String?, getTitle: String?, getValue: String?) {
        super.bind(showDisclosure: false, last: false)

        payTitleLabel.text = payTitle
        payValueLabel.text = payValue

        getTitleLabel.text = getTitle
        getValueLabel.text = getValue
    }

}
