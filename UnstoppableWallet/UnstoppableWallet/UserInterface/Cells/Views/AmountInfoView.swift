import UIKit

class AmountInfoView: UIView {
    private let secondaryAmountTitleLabel = UILabel()
    private let primaryAmountLabel = UILabel()
    private let secondaryAmountLabel = UILabel()
    private let primaryAmountTitleLabel = UILabel()

    var customPrimaryFractionPolicy: ValueFormatter.FractionPolicy = .full
    var primaryFormatTrimmable: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        addSubview(secondaryAmountTitleLabel)
        secondaryAmountTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview().inset(CGFloat.margin12)
        }

        secondaryAmountTitleLabel.font = .headline2
        secondaryAmountTitleLabel.textColor = .themeOz

        addSubview(primaryAmountLabel)
        primaryAmountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(secondaryAmountTitleLabel.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalToSuperview().inset(10)
        }

        primaryAmountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        primaryAmountLabel.font = .headline1
        primaryAmountLabel.textAlignment = .right

        addSubview(secondaryAmountLabel)
        secondaryAmountLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        secondaryAmountLabel.font = .subhead2
        secondaryAmountLabel.textColor = .themeGray
        secondaryAmountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(primaryAmountTitleLabel)
        primaryAmountTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(secondaryAmountLabel.snp.trailing).offset(CGFloat.margin16)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        primaryAmountTitleLabel.font = .subhead2
        primaryAmountTitleLabel.textColor = .themeGray
        primaryAmountTitleLabel.textAlignment = .right
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(primaryAmountInfo: AmountInfo, secondaryAmountInfo: AmountInfo?) {
        let primaryColor: UIColor = .themeLeah

        primaryAmountLabel.textColor = primaryColor

        let amountLabel: String?
        switch primaryAmountInfo {
        case .coinValue(let coinValue):
            primaryAmountTitleLabel.text = coinValue.coin.name
            amountLabel = ValueFormatter.instance.format(coinValueNew: coinValue)
        case .currencyValue(let currencyValue):
            primaryAmountTitleLabel.text = currencyValue.currency.code
            amountLabel = ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: customPrimaryFractionPolicy, trimmable: primaryFormatTrimmable)
        }
        primaryAmountLabel.text = amountLabel

        if let secondaryAmountInfo = secondaryAmountInfo {
            secondaryAmountLabel.text = secondaryAmountInfo.formattedString

            switch secondaryAmountInfo {
            case .coinValue(let coinValue): secondaryAmountTitleLabel.text = coinValue.coin.name
            case .currencyValue(let currencyValue): secondaryAmountTitleLabel.text = currencyValue.currency.code
            }
        }
    }

}
