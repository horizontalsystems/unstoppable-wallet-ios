import UIKit

class AmountInfoView: UIView {
    private let secondaryAmountTitleLabel = UILabel()
    private let primaryAmountLabel = UILabel()
    private let lockImageView = UIImageView()
    private let sentToSelfImageView = UIImageView()
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

        addSubview(lockImageView)

        addSubview(sentToSelfImageView)

        sentToSelfImageView.image = UIImage(named: "arrow_medium_main_down_left_20")?.withRenderingMode(.alwaysTemplate)
        sentToSelfImageView.tintColor = .themeRemus

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

    func bind(primaryAmountInfo: AmountInfo, secondaryAmountInfo: AmountInfo?, type: TransactionType = .outgoing, lockState: TransactionLockState? = nil) {
        let primaryColor: UIColor
        switch type {
        case .incoming:
            primaryColor = .themeGreenD
        case .outgoing, .sentToSelf:
            primaryColor = .themeYellowD
        case .approve:
            primaryColor = .themeLeah
        }

        primaryAmountLabel.textColor = primaryColor

        let amountLabel: String?
        switch primaryAmountInfo {
        case .coinValue(let coinValue):
            primaryAmountTitleLabel.text = coinValue.coin.title
            amountLabel = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            primaryAmountTitleLabel.text = currencyValue.currency.code
            amountLabel = ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: customPrimaryFractionPolicy, trimmable: primaryFormatTrimmable)
        }
        primaryAmountLabel.text = amountLabel

        if let secondaryAmountInfo = secondaryAmountInfo {
            secondaryAmountLabel.text = secondaryAmountInfo.formattedString

            switch secondaryAmountInfo {
            case .coinValue(let coinValue): secondaryAmountTitleLabel.text = coinValue.coin.title
            case .currencyValue(let currencyValue): secondaryAmountTitleLabel.text = currencyValue.currency.code
            }
        }

        if let lockState = lockState {
            lockImageView.image = UIImage(named: lockState.locked ? "lock_20" : "unlock_20")

            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(primaryAmountLabel.snp.trailing).offset(CGFloat.margin4)
                maker.centerY.equalTo(primaryAmountLabel)
                maker.size.equalTo(20)
            }
        } else {
            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(primaryAmountLabel.snp.trailing)
                maker.centerY.equalTo(primaryAmountLabel)
                maker.size.equalTo(0)
            }
        }

        if type == .sentToSelf {
            sentToSelfImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(lockImageView.snp.trailing).offset(CGFloat.margin4)
                maker.trailing.equalToSuperview().inset(CGFloat.margin16)
                maker.centerY.equalTo(primaryAmountLabel)
                maker.size.equalTo(20)
            }
        } else {
            sentToSelfImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(lockImageView.snp.trailing)
                maker.trailing.equalToSuperview().inset(CGFloat.margin16)
                maker.centerY.equalTo(primaryAmountLabel)
                maker.size.equalTo(0)
            }
        }
    }

}
