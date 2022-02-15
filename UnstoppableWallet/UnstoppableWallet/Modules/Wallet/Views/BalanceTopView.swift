import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class BalanceTopView: UIView {
    static let height: CGFloat = 68

    private let coinIconView = BalanceCoinIconHolder()
    private let testnetImageView = UIImageView()

    private let nameLabel = UILabel()
    private let blockchainBadgeView = BadgeView()

    private let currencyValueLabel = UILabel()

    private let bottomLeftLabel = UILabel()
    private let diffLabel = UILabel()
    private let bottomRightLabel = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(coinIconView)
        coinIconView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        addSubview(testnetImageView)
        testnetImageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.centerX.equalTo(coinIconView)
        }

        testnetImageView.image = UIImage(named: "testnet_16")?.withRenderingMode(.alwaysTemplate)
        testnetImageView.tintColor = .themeRed50

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinIconView.snp.trailing)
            maker.top.equalToSuperview().inset(14)
        }

        nameLabel.font = .headline2
        nameLabel.textColor = .themeOz
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(blockchainBadgeView)
        blockchainBadgeView.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.trailing).offset(CGFloat.margin8)
            maker.centerY.equalTo(nameLabel.snp.centerY)
        }

        blockchainBadgeView.set(style: .small)

        addSubview(currencyValueLabel)
        currencyValueLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(14)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        currencyValueLabel.font = .headline2

        addSubview(bottomLeftLabel)
        bottomLeftLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.leading)
            maker.top.equalTo(nameLabel.snp.bottom).offset(3)
        }

        bottomLeftLabel.font = .subhead2

        addSubview(diffLabel)
        diffLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(bottomLeftLabel.snp.trailing).offset(CGFloat.margin4)
            maker.centerY.equalTo(bottomLeftLabel)
        }

        diffLabel.font = .subhead2

        addSubview(bottomRightLabel)
        bottomRightLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalTo(bottomLeftLabel)
        }

        bottomRightLabel.font = .subhead2
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: BalanceTopViewItem, onTapError: (() -> ())?) {
        coinIconView.bind(
                iconUrlString: viewItem.iconUrlString,
                placeholderIconName: viewItem.placeholderIconName,
                spinnerProgress: viewItem.syncSpinnerProgress,
                indefiniteSearchCircle: viewItem.indefiniteSearchCircle,
                failViewVisible: viewItem.failedImageViewVisible,
                onTapError: onTapError
        )

        testnetImageView.isHidden = viewItem.isMainNet

        nameLabel.text = viewItem.coinCode

        if let blockchainBadge = viewItem.blockchainBadge {
            blockchainBadgeView.text = blockchainBadge
            blockchainBadgeView.isHidden = false
        } else {
            blockchainBadgeView.text = nil
            blockchainBadgeView.isHidden = true
        }

        if let currencyValue = viewItem.currencyValue {
            currencyValueLabel.text = currencyValue.text
            currencyValueLabel.textColor = currencyValue.dimmed ? .themeYellow50 : .themeJacob
        } else {
            currencyValueLabel.text = nil
        }

        switch viewItem.secondaryInfo {
        case let .amount(viewItem):
            bottomLeftLabel.text = viewItem.rateValue.text
            bottomLeftLabel.textColor = viewItem.rateValue.dimmed ? .themeGray50 : .themeGray

            if let diff = viewItem.diff {
                diffLabel.text = diff.text
                switch diff.type {
                case .dimmed: diffLabel.textColor = .themeGray50
                case .negative: diffLabel.textColor = .themeLucian
                case .positive: diffLabel.textColor = .themeRemus
                }
            } else {
                diffLabel.text = nil
            }

            if let coinValue = viewItem.coinValue {
                bottomRightLabel.text = coinValue.text
                bottomRightLabel.textColor = coinValue.dimmed ? .themeGray50 : .themeLeah
            } else {
                bottomRightLabel.text = nil
            }
        case let .searchingTx(count):
            diffLabel.text = nil

            bottomLeftLabel.text = "balance.searching".localized()
            bottomLeftLabel.textColor = .themeGray

            if count > 0 {
                bottomRightLabel.text = "balance.searching.count".localized("\(count)")
                bottomRightLabel.textColor = .themeGray
            } else {
                bottomRightLabel.text = nil
            }
        case let .syncing(progress, syncedUntil):
            diffLabel.text = nil

            if let progress = progress {
                bottomLeftLabel.text = "balance.syncing_percent".localized("\(progress)%")
            } else {
                bottomLeftLabel.text = "balance.syncing".localized
            }
            bottomLeftLabel.textColor = .themeGray

            if let syncedUntil = syncedUntil {
                bottomRightLabel.text = "balance.synced_through".localized(syncedUntil)
                bottomRightLabel.textColor = .themeGray
            } else {
                bottomRightLabel.text = nil
            }
        }
    }

}
