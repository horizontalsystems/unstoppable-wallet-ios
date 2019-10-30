import UIKit
import HUD
import RxSwift
import SnapKit
import XRatesKit

class BalanceCell: CardCell {
    static let height: CGFloat = 100
    static let expandedHeight: CGFloat = 160
    static let animationDuration = 0.15
    private static let minimumProgress = 10

    private let coinIconImageView = UIImageView()
    private let syncSpinner = HUDProgressView(
            progress: Float(BalanceCell.minimumProgress) / 100,
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
    private let coinValueLabel = UILabel()

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

        coinValueLabel.font = .appSubhead2

        clippingView.addSubview(coinValueLabel)
        coinValueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalTo(separatorView.snp.bottom).offset(CGFloat.margin3x)
        }

        currencyValueLabel.font = .appHeadline2
        currencyValueLabel.textAlignment = .right

        clippingView.addSubview(currencyValueLabel)
        currencyValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinValueLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalTo(coinValueLabel.snp.bottom)
        }

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
            maker.top.equalTo(coinValueLabel.snp.bottom).offset(CGFloat.margin3x)
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
            maker.width.equalTo(0)
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

    func bind(item: BalanceViewItem, selected: Bool, animated: Bool = false, onReceive: @escaping (() -> ()), onPay: @escaping (() -> ()), onChart: @escaping (() -> ())) {
        self.onPay = onPay
        self.onReceive = onReceive
        self.onChart = onChart

        bindView(item: item, selected: selected, animated: animated)
    }

    func bindView(item: BalanceViewItem, selected: Bool, animated: Bool = false) {
        coinIconImageView.image = UIImage(coin: item.coin)?.withRenderingMode(.alwaysTemplate)
        coinIconImageView.isHidden = item.state == .notSynced

        if case let .syncing(progress, _) = item.state {
            syncSpinner.isHidden = false
            syncSpinner.set(progress: Float(max(BalanceCell.minimumProgress, progress)) / 100)
            syncSpinner.startAnimating()
        } else {
            syncSpinner.isHidden = true
            syncSpinner.stopAnimating()
        }

        failedImageView.isHidden = item.state != .notSynced

        nameLabel.text = item.coin.title.localized

        if let value = item.exchangeValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) {
            rateLabel.text = item.diff != nil ? formattedValue : "balance.rate_per_coin".localized(formattedValue, item.coinValue.coin.code)
            rateLabel.textColor = item.marketInfoExpired ? .appGray50 : .appGray
        } else {
            rateLabel.text = " " // space required for constraints
        }

        if let diff = item.diff {
            rateDiffView.isHidden = false
            rateDiffView.set(value: diff)
        } else {
            rateDiffView.isHidden = true
        }

        if case let .syncing(progress, lastBlockDate) = item.state, !selected {
            currencyValueLabel.isHidden = true
            coinValueLabel.isHidden = true
            syncingLabel.isHidden = false
            syncedUntilLabel.isHidden = false

            if let lastBlockDate = lastBlockDate {
                syncingLabel.text = "balance.syncing_percent".localized("\(progress)%")
                syncedUntilLabel.text = "balance.synced_through".localized(DateHelper.instance.formatSyncedThroughDate(from: lastBlockDate))
            } else {
                syncingLabel.text = "balance.syncing".localized
                syncedUntilLabel.text = nil
            }
        } else {
            currencyValueLabel.isHidden = false
            coinValueLabel.isHidden = false
            syncingLabel.isHidden = true
            syncedUntilLabel.isHidden = true

            let syncedBalance = item.state == .synced || item.state == .notReady

            if let value = item.currencyValue, value.value != 0 {
                currencyValueLabel.text = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.01))
                currencyValueLabel.textColor = item.marketInfoExpired || !syncedBalance ? .appYellow50 : .appJacob
            } else {
                currencyValueLabel.text = nil
            }

            coinValueLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue, fractionPolicy: .threshold(high: 0.01, low: 0))
            coinValueLabel.textColor = syncedBalance ? .appLeah : .appGray50
        }

        receiveButton.set(hidden: !selected, animated: animated, duration: BalanceCell.animationDuration)
        sendButton.set(hidden: !selected, animated: animated, duration: BalanceCell.animationDuration)

        sendButton.isEnabled = item.state == .synced && item.coinValue.value > 0
        receiveButton.isEnabled = item.state != .notReady

        if let chartInfo = item.chartInfo {
            chartHolder.isHidden = false
            chartHolder.snp.updateConstraints { maker in
                maker.width.equalTo(72)
            }

            if chartInfo.points.isEmpty {
                chartView.clear()
            } else {
                let points = chartInfo.points.map {
                    ChartPointPosition(timestamp: $0.timestamp, value: $0.value)
                }
                chartView.set(gridIntervalType: GridIntervalConverter.convert(chartType: ChartType.day), data: points, start: chartInfo.startTimestamp, end: chartInfo.endTimestamp, animated: false)
            }

            notAvailableLabel.isHidden = !chartInfo.points.isEmpty
            chartHolder.isUserInteractionEnabled = !chartInfo.points.isEmpty
        } else {
            chartHolder.isHidden = true
            chartHolder.snp.updateConstraints { maker in
                maker.width.equalTo(0)
            }
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

    @objc func onChartTap() {
        onChart?()
    }

}
