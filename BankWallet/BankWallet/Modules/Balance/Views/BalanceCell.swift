import UIKit
import HUD
import RxSwift
import SnapKit
import XRatesKit

class BalanceCell: CardCell {
    static let height: CGFloat = 107
    static let expandedHeight: CGFloat = 165
    static let expandedLockedHeight: CGFloat = 190
    static let animationDuration = 0.15

    private let lockedInfoVisibleHeight = 25

    private let coinIconImageView = UIImageView()
    private let syncSpinner = HUDProgressView(
            progress: 0,
            strokeLineWidth: 2,
            radius: 15,
            strokeColor: .themeGray,
            duration: 2
    )
    private let failedImageView = UIImageView()

    private let nameLabel = UILabel()
    private let blockchainBadgeView = BadgeView()

    private let rateLabel = UILabel()
    private let rateDiffButton = RateDiffButton()

    private let coinValueLabel = UILabel()
    private let currencyValueLabel = UILabel()

    private let lockedInfoHolder = UIView()
    private let coinLockedIcon = UIImageView(image: UIImage(named: "Transaction Lock Icon"))
    private let currencyLockedValueLabel = UILabel()
    private let coinLockedValueLabel = UILabel()

    private let syncingLabel = UILabel()
    private let syncedUntilLabel = UILabel()

    private let receiveButton = UIButton.appGreen
    private let sendButton = UIButton.appYellow
    private let sendButtonWrapper = UIControl()     // disable touch events throw cell to tableView

    private var onPay: (() -> ())?
    private var onReceive: (() -> ())?
    private var onChart: (() -> ())?

    private var blockChart: Bool = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        let coinIconWrapper = UIView()

        clippingView.addSubview(coinIconWrapper)
        coinIconWrapper.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.width.height.equalTo(46)
        }

        coinIconWrapper.backgroundColor = .themeJeremy
        coinIconWrapper.cornerRadius = .cornerRadius2x

        coinIconWrapper.addSubview(coinIconImageView)
        coinIconImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        coinIconImageView.tintColor = .themeGray

        coinIconWrapper.addSubview(syncSpinner)
        syncSpinner.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        coinIconWrapper.addSubview(failedImageView)
        failedImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        failedImageView.image = UIImage(named: "Attention Icon")?.withRenderingMode(.alwaysTemplate)
        failedImageView.tintColor = .themeLucian

        clippingView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinIconWrapper.snp.trailing).offset(CGFloat.margin2x)
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
            maker.bottom.equalTo(coinIconWrapper.snp.bottom)
        }

        rateLabel.font = .subhead2
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let separatorView = UIView()

        clippingView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.top.equalTo(coinIconWrapper.snp.bottom).offset(CGFloat.margin3x)
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

        clippingView.addSubview(coinValueLabel)
        coinValueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalTo(separatorView.snp.top).offset(CGFloat.margin3x)
        }

        coinValueLabel.font = .subhead2
        coinValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        clippingView.addSubview(currencyValueLabel)
        currencyValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinValueLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalTo(coinValueLabel.snp.bottom)
        }

        currencyValueLabel.font = .headline2
        currencyValueLabel.textAlignment = .right

        clippingView.addSubview(lockedInfoHolder)
        lockedInfoHolder.snp.makeConstraints { maker in
            maker.height.equalTo(lockedInfoVisibleHeight)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.top.equalTo(coinValueLabel.snp.bottom)
        }

        lockedInfoHolder.backgroundColor = .clear
        lockedInfoHolder.clipsToBounds = true

        lockedInfoHolder.addSubview(coinLockedIcon)
        coinLockedIcon.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview()
        }

        coinLockedIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        lockedInfoHolder.addSubview(coinLockedValueLabel)
        coinLockedValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinLockedIcon.snp.trailing).offset(CGFloat.margin1x)
            maker.bottom.equalToSuperview()
        }

        coinLockedValueLabel.font = .subhead2
        coinLockedValueLabel.textColor = .themeGray

        lockedInfoHolder.addSubview(currencyLockedValueLabel)
        currencyLockedValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinLockedValueLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.bottom.equalToSuperview()
        }

        currencyLockedValueLabel.font = .subhead1
        currencyLockedValueLabel.textColor = .themeLeah
        currencyLockedValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

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

        clippingView.addSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin2x)
            maker.top.equalTo(lockedInfoHolder.snp.bottom).offset(CGFloat.margin3x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        receiveButton.setTitle("balance.deposit".localized, for: .normal)
        receiveButton.addTarget(self, action: #selector(onTapReceive), for: .touchUpInside)

        clippingView.addSubview(sendButtonWrapper)
        sendButtonWrapper.snp.makeConstraints { maker in
            maker.leading.equalTo(receiveButton.snp.trailing).offset(CGFloat.margin2x)
            maker.top.equalTo(receiveButton.snp.top)
            maker.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.width.equalTo(receiveButton.snp.width)
            maker.height.equalTo(CGFloat.heightButton)
        }

        clippingView.addSubview(sendButton)
        sendButton.snp.makeConstraints { maker in
            maker.edges.equalTo(sendButtonWrapper.snp.edges)
        }

        sendButton.setTitle("balance.send".localized, for: .normal)
        sendButton.addTarget(self, action: #selector(onTapSend), for: .touchUpInside)
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
        if let coinIconCode = item.coinIconCode {
            coinIconImageView.image = UIImage(named: "\(coinIconCode.lowercased())")?.withRenderingMode(.alwaysTemplate)
            coinIconImageView.isHidden = false
        } else {
            coinIconImageView.isHidden = true
        }

        if let syncSpinnerProgress = item.syncSpinnerProgress {
            syncSpinner.set(progress: Float(syncSpinnerProgress) / 100)
            syncSpinner.isHidden = false
            syncSpinner.startAnimating()
        } else {
            syncSpinner.isHidden = true
            syncSpinner.stopAnimating()
        }

        failedImageView.isHidden = !item.failedImageViewVisible

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

        if let currencyValue = item.currencyValue {
            currencyValueLabel.set(hidden: false, animated: animated, duration: BalanceCell.animationDuration)
            currencyValueLabel.text = currencyValue.text
            currencyValueLabel.textColor = currencyValue.dimmed ? .themeYellow50 : .themeJacob
        } else {
            currencyValueLabel.set(hidden: true, animated: animated, duration: BalanceCell.animationDuration)
        }

        if let coinValue = item.coinValue {
            coinValueLabel.set(hidden: false, animated: animated, duration: BalanceCell.animationDuration)
            coinValueLabel.text = coinValue.text
            coinValueLabel.textColor = coinValue.dimmed ? .themeGray50 : .themeLeah
        } else {
            coinValueLabel.set(hidden: true, animated: animated, duration: BalanceCell.animationDuration)
        }

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

            syncingLabel.set(hidden: false, animated: animated, duration: BalanceCell.animationDuration)
            syncedUntilLabel.set(hidden: false, animated: animated, duration: BalanceCell.animationDuration)
        } else {
            syncingLabel.set(hidden: true, animated: animated, duration: BalanceCell.animationDuration)
            syncedUntilLabel.set(hidden: true, animated: animated, duration: BalanceCell.animationDuration)
        }

        lockedInfoHolder.snp.updateConstraints { maker in
            maker.height.equalTo(item.lockedVisible ? lockedInfoVisibleHeight : 0)
        }

        if let lockedCoinValue = item.lockedCoinValue {
            lockedInfoHolder.set(hidden: false, animated: animated, duration: BalanceCell.animationDuration)

            coinLockedValueLabel.text = lockedCoinValue.text

            if let lockedCurrencyValue = item.lockedCurrencyValue {
                currencyLockedValueLabel.text = lockedCurrencyValue.text
            } else {
                currencyLockedValueLabel.text = nil
            }
        } else {
            lockedInfoHolder.set(hidden: true, animated: animated, duration: BalanceCell.animationDuration)
        }

        if let enabled = item.receiveButtonEnabled {
            receiveButton.set(hidden: false, animated: animated, duration: BalanceCell.animationDuration)
            receiveButton.isEnabled = enabled
        } else {
            receiveButton.set(hidden: true, animated: animated, duration: BalanceCell.animationDuration)
        }

        if let enabled = item.sendButtonEnabled {
            sendButton.set(hidden: false, animated: animated, duration: BalanceCell.animationDuration)
            sendButton.isEnabled = enabled
        } else {
            sendButton.set(hidden: true, animated: animated, duration: BalanceCell.animationDuration)
        }
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
