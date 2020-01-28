import UIKit

class AmountInfoView: UIView {
    private let primaryAmountLabel = UILabel()
    private let lockImageView = UIImageView()
    private let sentToSelfImageView = UIImageView()
    private let primaryAmountTitleLabel = UILabel()
    private let secondaryAmountLabel = UILabel()
    private let secondaryAmountTitleLabel = UILabel()

    var customPrimaryFractionPolicy: ValueFormatter.FractionPolicy = .full
    var primaryFormatTrimmable: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        addSubview(primaryAmountLabel)
        addSubview(lockImageView)
        addSubview(sentToSelfImageView)
        addSubview(primaryAmountTitleLabel)
        addSubview(secondaryAmountLabel)
        addSubview(secondaryAmountTitleLabel)

        primaryAmountLabel.font = .headline1
        primaryAmountLabel.textAlignment = .right
        primaryAmountLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.equalTo(secondaryAmountTitleLabel.snp.trailing).offset(CGFloat.margin4x)
        }

        lockImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(primaryAmountLabel.snp.trailing)
            maker.top.equalToSuperview().inset(CGFloat.margin4x)
            maker.size.equalTo(0)
        }
        lockImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        sentToSelfImageView.image = UIImage(named: "Transaction In Icon")
        sentToSelfImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(lockImageView.snp.trailing)
            maker.top.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.size.equalTo(0)
        }
        sentToSelfImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        primaryAmountTitleLabel.font = .subhead2
        primaryAmountTitleLabel.textColor = .themeGray
        primaryAmountTitleLabel.textAlignment = .right
        primaryAmountTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(secondaryAmountLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        secondaryAmountTitleLabel.font = .headline2
        secondaryAmountTitleLabel.textColor = .themeOz
        secondaryAmountTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        secondaryAmountLabel.font = .subhead2
        secondaryAmountLabel.textColor = .themeGray
        secondaryAmountLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        primaryAmountTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        primaryAmountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        secondaryAmountTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        secondaryAmountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(primaryAmountInfo: AmountInfo, secondaryAmountInfo: AmountInfo?, type: TransactionType = .outgoing, locked: Bool? = nil) {
        primaryAmountLabel.textColor = type == .incoming ? .themeRemus : .themeJacob

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

        guard let secondaryAmountInfo = secondaryAmountInfo else {
            return
        }
        secondaryAmountLabel.text = secondaryAmountInfo.formattedString

        switch secondaryAmountInfo {
        case .coinValue(let coinValue): secondaryAmountTitleLabel.text = coinValue.coin.title
        case .currencyValue(let currencyValue): secondaryAmountTitleLabel.text = currencyValue.currency.code
        }

        if let txLocked = locked {
            lockImageView.image = UIImage(named: txLocked ? "Transaction Lock Icon" : "Transaction Unlock Icon")
            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(primaryAmountLabel.snp.trailing).offset(CGFloat.margin1x)
                maker.top.equalToSuperview().inset(CGFloat.margin4x)
            }
        } else {
            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(primaryAmountLabel.snp.trailing)
                maker.top.equalToSuperview().inset(CGFloat.margin4x)
                maker.size.equalTo(0)
            }
        }

        if type == .sentToSelf {
            sentToSelfImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(lockImageView.snp.trailing).offset(CGFloat.margin1x)
                maker.top.trailing.equalToSuperview().inset(CGFloat.margin4x)
                maker.size.equalTo(16)
            }
        } else {
            sentToSelfImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(lockImageView.snp.trailing)
                maker.top.trailing.equalToSuperview().inset(CGFloat.margin4x)
                maker.size.equalTo(0)
            }
        }
    }

}
