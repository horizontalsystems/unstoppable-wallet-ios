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

    private let primaryValueLabel = UILabel()

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

        let topStackView = UIStackView()

        addSubview(topStackView)
        topStackView.snp.makeConstraints { maker in
            maker.leading.equalTo(coinIconView.snp.trailing)
            maker.top.equalToSuperview().inset(14)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        topStackView.alignment = .center
        topStackView.distribution = .fill
        topStackView.axis = .horizontal
        topStackView.spacing = .margin8

        let bottomStackView = UIStackView()

        addSubview(bottomStackView)
        bottomStackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(topStackView)
            maker.top.equalTo(topStackView.snp.bottom).offset(3)
        }

        bottomStackView.alignment = .center
        bottomStackView.distribution = .fill
        bottomStackView.axis = .horizontal
        bottomStackView.spacing = .margin4

        topStackView.addArrangedSubview(nameLabel)
        nameLabel.font = .headline2
        nameLabel.textColor = .themeLeah
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)

        topStackView.addArrangedSubview(blockchainBadgeView)
        blockchainBadgeView.set(style: .small)

        let topSpacerView = UIView()
        topStackView.addArrangedSubview(topSpacerView)

        topStackView.addArrangedSubview(primaryValueLabel)
        primaryValueLabel.textAlignment = .right
        primaryValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        primaryValueLabel.font = .headline2

        bottomStackView.addArrangedSubview(bottomLeftLabel)
        bottomLeftLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        bottomLeftLabel.setContentHuggingPriority(.required, for: .horizontal)
        bottomLeftLabel.font = .subhead2

        bottomStackView.addArrangedSubview(diffLabel)
        diffLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        diffLabel.setContentHuggingPriority(.required, for: .horizontal)
        diffLabel.font = .subhead2

        let bottomSpacerView = UIView()
        bottomStackView.addArrangedSubview(bottomSpacerView)

        bottomStackView.addArrangedSubview(bottomRightLabel)
        bottomRightLabel.textAlignment = .right
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
            blockchainBadgeView.isHidden = true
        }

        if let primaryValue = viewItem.primaryValue {
            primaryValueLabel.isHidden = false
            primaryValueLabel.text = primaryValue.text
            primaryValueLabel.textColor = primaryValue.dimmed ? .themeGray50 : .themeLeah
        } else {
            primaryValueLabel.isHidden = true
        }

        switch viewItem.secondaryInfo {
        case let .amount(viewItem):
            bottomLeftLabel.text = viewItem.rateValue.text
            bottomLeftLabel.textColor = viewItem.rateValue.dimmed ? .themeGray50 : .themeGray

            if let diff = viewItem.diff {
                diffLabel.isHidden = false
                diffLabel.text = diff.text

                switch diff.type {
                case .dimmed: diffLabel.textColor = .themeGray50
                case .negative: diffLabel.textColor = .themeLucian
                case .positive: diffLabel.textColor = .themeRemus
                }
            } else {
                diffLabel.isHidden = true
            }

            if let secondaryValue = viewItem.secondaryValue {
                bottomRightLabel.isHidden = false
                bottomRightLabel.text = secondaryValue.text
                bottomRightLabel.textColor = secondaryValue.dimmed ? .themeGray50 : .themeGray
            } else {
                bottomRightLabel.isHidden = true
            }
        case let .syncing(progress, syncedUntil):
            diffLabel.isHidden = true

            if let progress = progress {
                bottomLeftLabel.text = "balance.syncing_percent".localized("\(progress)%")
            } else {
                bottomLeftLabel.text = "balance.syncing".localized
            }
            bottomLeftLabel.textColor = .themeGray

            if let syncedUntil = syncedUntil {
                bottomRightLabel.isHidden = false
                bottomRightLabel.text = "balance.synced_through".localized(syncedUntil)
                bottomRightLabel.textColor = .themeGray
            } else {
                bottomRightLabel.isHidden = true
            }
        case let .customSyncing(left, right):
            diffLabel.isHidden = true

            bottomLeftLabel.text = left
            bottomLeftLabel.textColor = .themeGray
            if let right = right {
                bottomRightLabel.isHidden = false
                bottomRightLabel.text = right
                bottomRightLabel.textColor = .themeGray
            } else {
                bottomRightLabel.isHidden = true
            }
        }
    }

}
