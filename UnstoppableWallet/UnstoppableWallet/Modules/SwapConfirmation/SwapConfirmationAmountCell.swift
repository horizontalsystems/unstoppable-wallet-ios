import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class SwapConfirmationAmountCell: BaseThemeCell {
    static let height: CGFloat = 72

    private let payTitleLabel = UILabel()
    private let payValueLabel = UILabel()

    private let getTitleLabel = UILabel()
    private let getValueLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        wrapperView.addSubview(payTitleLabel)
        payTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        payTitleLabel.font = .headline2
        payTitleLabel.textColor = .themeLeah

        wrapperView.addSubview(payValueLabel)
        payValueLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.leading.equalTo(payTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        payValueLabel.font = .subhead1
        payValueLabel.textColor = .themeLeah
        payValueLabel.textAlignment = .right

        payTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        payValueLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        wrapperView.addSubview(getTitleLabel)
        getTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        getTitleLabel.font = .subhead2
        getTitleLabel.textColor = .themeGray

        wrapperView.addSubview(getValueLabel)
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(payTitle: String?, payValue: String?, getTitle: String?, getValue: String?) {
        payTitleLabel.text = payTitle
        payValueLabel.text = payValue

        getTitleLabel.text = getTitle
        getValueLabel.text = getValue
    }

}
