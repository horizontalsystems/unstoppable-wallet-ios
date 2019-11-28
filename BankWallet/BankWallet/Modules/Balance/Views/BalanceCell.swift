import UIKit
import HUD
import RxSwift
import SnapKit
import XRatesKit

class BalanceCell: CardCell {
    static let height: CGFloat = 100
    static let expandedHeight: CGFloat = 160
    static let expandedLockedHeight: CGFloat = 188
    static let animationDuration = 0.15

    private let lockedInfoVisibleHeight = 29

    private let coinIconImageView = UIImageView()
    private let syncSpinner = HUDProgressView(
            progress: 0,
            strokeLineWidth: 2,
            radius: 15,
            strokeColor: .appGray,
            duration: 2
    )
    private let failedImageView = UIImageView()

    private let nameLabel = UILabel()
    private let rateLabel = UILabel()
    private let rateDiffView = RateDiffView()

    private let currencyValueLabel = UILabel()

    private let coinValueWrapper = UIView()
    private let coinValueLabel = UILabel()
    private let blockchainBadgeView = BadgeView()

    private let lockedInfoHolder = UIView()
    private let coinLockedIcon = UIImageView(image: UIImage(named: "Transaction Lock Icon"))
    private let currencyLockedValueLabel = UILabel()
    private let coinLockedValueLabel = UILabel()

    private let syncingLabel = UILabel()
    private let syncedUntilLabel = UILabel()

    private let receiveButton = UIButton.appGreen
    private let sendButton = UIButton.appYellow

    private let chartHolder = UIButton()
    private let chartView: ChartView
    private let notAvailableLabel = UILabel()

    private var onPay: (() -> ())?
    private var onReceive: (() -> ())?
    private var onChart: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let configuration = ChartConfiguration()
        configuration.showGrid = false
        chartView = ChartView(configuration: configuration, gridIntervalType: GridIntervalConverter.convert(chartType: .day))

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        let coinIconWrapper = UIView()
        coinIconWrapper.backgroundColor = .appJeremy
        coinIconWrapper.cornerRadius = .cornerRadius8

        clippingView.addSubview(coinIconWrapper)
        coinIconWrapper.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.width.height.equalTo(CGFloat.heightSingleLineCell)
        }

        coinIconImageView.tintColor = .appGray

        coinIconWrapper.addSubview(coinIconImageView)
        coinIconImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        coinIconWrapper.addSubview(syncSpinner)
        syncSpinner.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        failedImageView.image = UIImage(named: "Attention Icon")

        coinIconWrapper.addSubview(failedImageView)
        failedImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        nameLabel.font = .appHeadline2
        nameLabel.textColor = .appLeah
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        clippingView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinIconWrapper.snp.trailing).offset(CGFloat.margin2x)
            maker.top.equalTo(coinIconWrapper.snp.top).offset(CGFloat.margin05x)
        }

        rateLabel.font = .appSubhead2
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        clippingView.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.leading)
            maker.top.equalTo(nameLabel.snp.bottom).offset(CGFloat.margin1x)
        }

        rateDiffView.font = .appSubhead2

        clippingView.addSubview(rateDiffView)
        rateDiffView.snp.makeConstraints { maker in
            maker.leading.equalTo(rateLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.centerY.equalTo(rateLabel.snp.centerY)
        }

        let separatorView = UIView()
        separatorView.backgroundColor = .appSteel20

        clippingView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.top.equalTo(coinIconWrapper.snp.bottom).offset(CGFloat.margin2x)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        clippingView.addSubview(coinValueWrapper)
        coinValueWrapper.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalTo(separatorView.snp.bottom).offset(CGFloat.margin3x)
        }

        coinValueWrapper.addSubview(coinValueLabel)
        coinValueLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        coinValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        coinValueLabel.font = .appSubhead2

        coinValueWrapper.addSubview(blockchainBadgeView)
        blockchainBadgeView.snp.makeConstraints { maker in
            maker.leading.equalTo(coinValueLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.trailing.centerY.equalToSuperview()
        }

        currencyValueLabel.font = .appHeadline2
        currencyValueLabel.textAlignment = .right

        clippingView.addSubview(currencyValueLabel)
        currencyValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinValueWrapper.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalTo(coinValueWrapper.snp.bottom)
        }

        clippingView.addSubview(lockedInfoHolder)
        lockedInfoHolder.snp.makeConstraints { maker in
            maker.height.equalTo(lockedInfoVisibleHeight)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.top.equalTo(coinValueWrapper.snp.bottom)
        }

        lockedInfoHolder.backgroundColor = .clear
        lockedInfoHolder.clipsToBounds = true

        lockedInfoHolder.addSubview(coinLockedIcon)
        coinLockedIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        coinLockedIcon.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview()
        }

        lockedInfoHolder.addSubview(coinLockedValueLabel)
        coinLockedValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinLockedIcon.snp.trailing).offset(CGFloat.margin1x)
            maker.bottom.equalToSuperview()
        }

        coinLockedValueLabel.font = .appSubhead2
        coinLockedValueLabel.textColor = .appGray

        lockedInfoHolder.addSubview(currencyLockedValueLabel)
        currencyLockedValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        currencyLockedValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinLockedValueLabel.snp.trailing)
            maker.trailing.bottom.equalToSuperview()
        }

        currencyLockedValueLabel.font = .appSubhead1
        currencyLockedValueLabel.textColor = .appLeah

        syncingLabel.font = .appSubhead2
        syncingLabel.textColor = .appGray

        clippingView.addSubview(syncingLabel)
        syncingLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalTo(separatorView.snp.bottom).offset(CGFloat.margin3x)
        }

        syncedUntilLabel.font = .appSubhead2
        syncedUntilLabel.textColor = .appGray
        syncedUntilLabel.textAlignment = .right

        clippingView.addSubview(syncedUntilLabel)
        syncedUntilLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(syncingLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalTo(syncingLabel.snp.bottom)
        }

        receiveButton.setTitle("balance.deposit".localized, for: .normal)
        receiveButton.addTarget(self, action: #selector(onTapReceive), for: .touchUpInside)

        clippingView.addSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin2x)
            maker.top.equalTo(lockedInfoHolder.snp.bottom).offset(CGFloat.margin3x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        sendButton.setTitle("balance.send".localized, for: .normal)
        sendButton.addTarget(self, action: #selector(onTapSend), for: .touchUpInside)

        clippingView.addSubview(sendButton)
        sendButton.snp.makeConstraints { maker in
            maker.leading.equalTo(receiveButton.snp.trailing).offset(CGFloat.margin2x)
            maker.top.equalTo(receiveButton.snp.top)
            maker.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.width.equalTo(receiveButton.snp.width)
            maker.height.equalTo(CGFloat.heightButton)
        }

        chartHolder.addTarget(self, action: #selector(onChartTap), for: .touchUpInside)

        clippingView.addSubview(chartHolder)
        chartHolder.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.trailing).offset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview()
            maker.height.equalTo(38)
            maker.width.equalTo(72)
        }

        chartView.isUserInteractionEnabled = false

        chartHolder.addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin3x).priority(.low)
        }

        notAvailableLabel.font = .appSubhead2
        notAvailableLabel.textColor = .appGray50
        notAvailableLabel.text = "n/a".localized

        chartHolder.addSubview(notAvailableLabel)
        notAvailableLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin1x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: BalanceViewItem, animated: Bool = false, onReceive: @escaping (() -> ()), onPay: @escaping (() -> ()), onChart: @escaping (() -> ())) {
        self.onPay = onPay
        self.onReceive = onReceive
        self.onChart = onChart

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
            rateLabel.textColor = rateValue.dimmed ? .appGray50 : .appGray
        } else {
            rateLabel.text = " " // space required for constraints
        }

        if let diff = item.diff {
            rateDiffView.set(value: diff, highlightText: false)
            rateDiffView.isHidden = false
        } else {
            rateDiffView.isHidden = true
        }

        if let currencyValue = item.currencyValue {
            currencyValueLabel.text = currencyValue.text
            currencyValueLabel.textColor = currencyValue.dimmed ? .appYellow50 : .appJacob
        } else {
            currencyValueLabel.text = nil
        }

        if let coinValue = item.coinValue {
            coinValueLabel.text = coinValue.text
            coinValueLabel.textColor = coinValue.dimmed ? .appGray50 : .appLeah
            coinValueWrapper.isHidden = false
        } else {
            coinValueWrapper.isHidden = true
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

            syncingLabel.isHidden = false
            syncedUntilLabel.isHidden = false
        } else {
            syncingLabel.isHidden = true
            syncedUntilLabel.isHidden = true
        }

        if let lockedCoinValue = item.lockedCoinValue {
            coinLockedValueLabel.text = lockedCoinValue.text

            if let lockedCurrencyValue = item.lockedCurrencyValue {
                currencyLockedValueLabel.text = lockedCurrencyValue.text
            } else {
                currencyLockedValueLabel.text = nil
            }

            lockedInfoHolder.snp.updateConstraints { maker in
                maker.height.equalTo(lockedInfoVisibleHeight)
            }
        } else {
            lockedInfoHolder.snp.updateConstraints { maker in
                maker.height.equalTo(0)
            }
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

        if let chartInfo = item.chartInfo {
            let points = chartInfo.points.map {
                ChartPointPosition(timestamp: $0.timestamp, value: $0.value)
            }

            chartView.set(gridIntervalType: GridIntervalConverter.convert(chartType: ChartType.day), data: points, start: chartInfo.startTimestamp, end: chartInfo.endTimestamp, animated: false)
            chartView.isHidden = false
            chartHolder.isUserInteractionEnabled = true
        } else {
            chartView.isHidden = true
            chartHolder.isUserInteractionEnabled = false
        }

        notAvailableLabel.isHidden = !item.chartNotAvailableVisible
    }

    func unbind() {
    }

    @objc func onTapReceive() {
        onReceive?()
    }

    @objc func onTapSend() {
        onPay?()
    }

    @objc func onChartTap() {
        onChart?()
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
