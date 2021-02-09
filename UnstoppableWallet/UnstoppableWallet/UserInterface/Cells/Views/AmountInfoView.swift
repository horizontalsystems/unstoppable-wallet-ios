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

        let primaryAmountWrapper = UIView()
        let secondaryAmountWrapper = UIView()

        secondaryAmountWrapper.addSubview(secondaryAmountLabel)
        secondaryAmountLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin1x)
        }
        secondaryAmountLabel.font = .subhead2
        secondaryAmountLabel.textColor = .themeGray
        secondaryAmountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        secondaryAmountWrapper.addSubview(secondaryAmountTitleLabel)
        secondaryAmountTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin1x)
        }
        secondaryAmountTitleLabel.font = .headline2
        secondaryAmountTitleLabel.textColor = .themeOz
        secondaryAmountTitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        primaryAmountWrapper.addSubview(primaryAmountLabel)
        primaryAmountLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin1x)
        }
        primaryAmountLabel.font = .headline1
        primaryAmountLabel.textAlignment = .right

        primaryAmountWrapper.addSubview(lockImageView)
        lockImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        lockImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        primaryAmountWrapper.addSubview(sentToSelfImageView)
        sentToSelfImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        sentToSelfImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        sentToSelfImageView.image = UIImage(named: "arrow_medium_main_down_left_20")?.tinted(with: .themeRemus)

        primaryAmountWrapper.addSubview(primaryAmountTitleLabel)
        primaryAmountTitleLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        primaryAmountTitleLabel.font = .subhead2
        primaryAmountTitleLabel.textColor = .themeGray
        primaryAmountTitleLabel.textAlignment = .right

        addSubview(secondaryAmountWrapper)
        secondaryAmountWrapper.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
            maker.width.lessThanOrEqualToSuperview().multipliedBy(0.5)
        }

        addSubview(primaryAmountWrapper)
        primaryAmountWrapper.snp.makeConstraints { maker in
            maker.trailing.top.bottom.equalToSuperview()
            maker.leading.equalTo(secondaryAmountWrapper.snp.trailing)
        }
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
