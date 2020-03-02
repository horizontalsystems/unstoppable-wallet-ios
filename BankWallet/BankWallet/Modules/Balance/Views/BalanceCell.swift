import UIKit
import HUD
import ThemeKit
import RxSwift
import SnapKit
import XRatesKit

class BalanceCell: CardCell {
    static let height: CGFloat = 107
    static let expandedHeight: CGFloat = 165
    static let expandedLockedHeight: CGFloat = 190

    private let lockedInfoVisibleHeight = 25

    private let coinIconView = BalanceCoinIconHolder()

    private let nameLabel = UILabel()
    private let blockchainBadgeView = BadgeView()

    private let rateLabel = UILabel()
    private let rateDiffButton = RateDiffButton()

    private let balanceView = BalanceDoubleRowView(frame: .zero)

    private let lockedInfoHolder = SecondaryBalanceDoubleRowView(frame: .zero)

    private let syncingLabel = UILabel()
    private let syncedUntilLabel = UILabel()

    private let buttonsView = DoubleRowButtonView(leftButton: .appGreen, rightButton: .appYellow)

    private var onPay: (() -> ())?
    private var onReceive: (() -> ())?
    private var onChart: (() -> ())?

    private var blockChart: Bool = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        clippingView.addSubview(coinIconView)
        coinIconView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.width.height.equalTo(46)
        }

        clippingView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinIconView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        nameLabel.font = .headline2
        nameLabel.textColor = .themeLeah
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        clippingView.addSubview(blockchainBadgeView)
        blockchainBadgeView.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.centerY.equalTo(nameLabel.snp.centerY)
        }

        clippingView.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.leading)
            maker.bottom.equalTo(coinIconView.snp.bottom)
        }

        rateLabel.font = .subhead2
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let separatorView = UIView()

        clippingView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.top.equalTo(coinIconView.snp.bottom).offset(CGFloat.margin3x)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        clippingView.addSubview(rateDiffButton)
        rateDiffButton.snp.makeConstraints { maker in
            maker.leading.greaterThanOrEqualTo(blockchainBadgeView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalTo(separatorView.snp.top).offset(-CGFloat.margin3x)
            maker.width.equalTo(80)
        }

        rateDiffButton.addTarget(self, action: #selector(onTapChart), for: .touchUpInside)

        clippingView.addSubview(balanceView)
        balanceView.snp.makeConstraints { maker in
            maker.top.equalTo(separatorView)
            maker.leading.trailing.equalToSuperview()
        }

        clippingView.addSubview(lockedInfoHolder)
        lockedInfoHolder.snp.makeConstraints { maker in
            maker.height.equalTo(lockedInfoVisibleHeight)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.top.equalTo(balanceView.snp.bottom)
        }

        clippingView.addSubview(syncingLabel)
        syncingLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalTo(separatorView.snp.bottom).offset(CGFloat.margin3x)
        }

        syncingLabel.font = .subhead2
        syncingLabel.textColor = .themeGray

        clippingView.addSubview(syncedUntilLabel)
        syncedUntilLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(syncingLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalTo(syncingLabel.snp.bottom)
        }

        syncedUntilLabel.font = .subhead2
        syncedUntilLabel.textColor = .themeGray
        syncedUntilLabel.textAlignment = .right

        clippingView.addSubview(buttonsView)
        buttonsView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(lockedInfoHolder.snp.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: BalanceViewItem, animated: Bool = false, onReceive: @escaping (() -> ()), onPay: @escaping (() -> ()), onChart: @escaping (() -> ())) {
        self.onPay = onPay
        self.onReceive = onReceive
        self.onChart = onChart
        self.blockChart = item.blockChart

        bindView(item: item, animated: animated)
    }

    func bindView(item: BalanceViewItem, animated: Bool = false) {
        let coinIcon = item.coinIconCode.flatMap { UIImage(named: "\($0.lowercased())") }
        coinIconView.bind(coinIcon: coinIcon, spinnerProgress: item.syncSpinnerProgress, failViewVisible: item.failedImageViewVisible)

        nameLabel.text = item.coinTitle

        if let rateValue = item.rateValue {
            rateLabel.text = rateValue.text
            rateLabel.textColor = rateValue.dimmed ? .themeGray50 : .themeGray
        } else {
            rateLabel.text = " " // space required for constraints
        }

        if let diff = item.diff {
            rateDiffButton.show(value: diff.value, dimmed: diff.dimmed)
        } else {
            rateDiffButton.showNotAvailable()
        }

        balanceView.bind(coinValue: item.coinValue, currencyValue: item.currencyValue, animated: animated)

        if let blockchainBadge = item.blockchainBadge {
            blockchainBadgeView.set(text: blockchainBadge)
            blockchainBadgeView.isHidden = false
        } else {
            blockchainBadgeView.isHidden = true
        }

        if let syncingInfo = item.syncingInfo {
            if let progress = syncingInfo.progress {
                syncingLabel.text = "balance.syncing_percent".localized("\(progress)%")
            } else {
                syncingLabel.text = "balance.syncing".localized
            }

            if let syncedUntil = syncingInfo.syncedUntil {
                syncedUntilLabel.text = "balance.synced_through".localized(syncedUntil)
            } else {
                syncedUntilLabel.text = nil
            }

            syncingLabel.set(hidden: false, animated: animated, duration: CardCell.animationDuration)
            syncedUntilLabel.set(hidden: false, animated: animated, duration: CardCell.animationDuration)
        } else {
            syncingLabel.set(hidden: true, animated: animated, duration: CardCell.animationDuration)
            syncedUntilLabel.set(hidden: true, animated: animated, duration: CardCell.animationDuration)
        }

        lockedInfoHolder.snp.updateConstraints { maker in
            maker.height.equalTo(item.lockedVisible ? lockedInfoVisibleHeight : 0)
        }
        lockedInfoHolder.bind(image: UIImage(named: "Transaction Lock Icon"), coinValue: item.lockedCoinValue, currencyValue: item.lockedCurrencyValue, animated: animated)

        buttonsView.bind(
                left: (title: "balance.deposit".localized, enabled: item.receiveButtonEnabled, action: onReceive),
                right: (title: "balance.send".localized, enabled: item.sendButtonEnabled, action: onPay),
                animated: animated
        )
    }

    func unbind() {
    }

    @objc func onTapReceive() {
        onReceive?()
    }

    @objc func onTapSend() {
        onPay?()
    }

    @objc func onTapChart() {
        if !blockChart {
            onChart?()
        }
    }

    static func height(item: BalanceViewItem) -> CGFloat {
        if item.expanded {
            if item.lockedCoinValue != nil {
                return BalanceCell.expandedLockedHeight
            } else {
                return BalanceCell.expandedHeight
            }
        } else {
            return BalanceCell.height
        }
    }

}
