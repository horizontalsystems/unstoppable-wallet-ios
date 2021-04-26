import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class BalanceTopView: UIView {
    static let height: CGFloat = 50

    private let coinIconView = BalanceCoinIconHolder()

    private let nameLabel = UILabel()
    private let blockchainBadgeView = BadgeView()

    private let rateLabel = UILabel()
    private let rateDiffButton = RateDiffButton()

    private var onTapRateDiff: (() -> ())?

    init() {
        super.init(frame: .zero)

        addSubview(coinIconView)
        coinIconView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
        }

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinIconView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.equalToSuperview().offset(CGFloat.margin05x)
        }

        nameLabel.font = .headline2
        nameLabel.textColor = .themeLeah
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(blockchainBadgeView)
        blockchainBadgeView.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.centerY.equalTo(nameLabel.snp.centerY)
        }

        addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.leading)
            maker.bottom.equalTo(coinIconView.snp.bottom)
        }

        rateLabel.font = .subhead2
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(rateDiffButton)
        rateDiffButton.snp.makeConstraints { maker in
            maker.leading.greaterThanOrEqualTo(blockchainBadgeView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.trailing.equalToSuperview()
            maker.bottom.equalToSuperview().inset(CGFloat.margin1x)
            maker.width.equalTo(80)
        }

        rateDiffButton.addTarget(self, action: #selector(_onTapRateDiff), for: .touchUpInside)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: BalanceTopViewItem, onTapRateDiff: @escaping () -> (), onTapError: (() -> ())?) {
        self.onTapRateDiff = onTapRateDiff

        let coinIcon = viewItem.iconCoinType.flatMap { UIImage.image(coinType: $0) }
        coinIconView.bind(
                coinIcon: coinIcon, spinnerProgress: viewItem.syncSpinnerProgress, indefiniteSearchCircle: viewItem.indefiniteSearchCircle,
                failViewVisible: viewItem.failedImageViewVisible, onTapError: onTapError
        )

        nameLabel.text = viewItem.coinTitle

        if let blockchainBadge = viewItem.blockchainBadge {
            blockchainBadgeView.text = blockchainBadge
            blockchainBadgeView.isHidden = false
        } else {
            blockchainBadgeView.text = nil
            blockchainBadgeView.isHidden = true
        }

        if let rateValue = viewItem.rateValue {
            rateLabel.text = rateValue.text
            rateLabel.textColor = rateValue.dimmed ? .themeGray50 : .themeGray
        } else {
            rateLabel.text = " " // space required for constraints
        }

        if let diff = viewItem.diff {
            rateDiffButton.show(value: diff.value, dimmed: diff.dimmed)
        } else {
            rateDiffButton.showNotAvailable()
        }
    }

    @objc private func _onTapRateDiff() {
        onTapRateDiff?()
    }

}
