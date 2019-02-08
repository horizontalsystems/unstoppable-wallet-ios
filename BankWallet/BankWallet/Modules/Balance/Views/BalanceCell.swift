import UIKit
import GrouviExtensions
import GrouviHUD
import RxSwift

class BalanceCell: UITableViewCell {
    private static let minimumProgress: Float = 0.1

    private var progressDisposable: Disposable?

    private let roundedBackground = UIView()

    private let coinIconImageView = CoinIconImageView()
    private let nameLabel = UILabel()
    private let currencyValueLabel = UILabel()
    private let coinValueLabel = UILabel()
    private let rateLabel = UILabel()

    private let syncSpinner = HUDProgressView(
            progress: BalanceCell.minimumProgress,
            strokeLineWidth: BalanceTheme.spinnerLineWidth,
            radius: BalanceTheme.spinnerDonutRadius,
            strokeColor: BalanceTheme.spinnerLineColor,
            donutColor: BalanceTheme.spinnerDonutColor,
            duration: 2
    )

    private let failedImageView = UIImageView()

    private let receiveButton = RespondButton()
    private let payButton = RespondButton()

    private var onPay: (() -> ())?
    private var onReceive: (() -> ())?

    private var progressDateString: String?
    private var expanded = false

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(roundedBackground)
        roundedBackground.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(BalanceTheme.cellPadding)
            maker.leadingMargin.trailingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.bottom.equalToSuperview()
        }
        roundedBackground.backgroundColor = BalanceTheme.roundedBackgroundColor
        roundedBackground.clipsToBounds = true
        roundedBackground.layer.cornerRadius = BalanceTheme.roundedBackgroundCornerRadius

        coinIconImageView.tintColor = BalanceTheme.coinIconTintColor
        roundedBackground.addSubview(coinIconImageView)
        coinIconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BalanceTheme.cellBigMargin)
            maker.top.equalToSuperview().offset(BalanceTheme.cellSmallMargin)
            maker.size.equalTo(BalanceTheme.coinIconSide)
        }

        roundedBackground.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.coinIconImageView.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.centerY.equalTo(self.coinIconImageView.snp.centerY)
        }
        nameLabel.font = BalanceTheme.cellTitleFont
        nameLabel.textColor = BalanceTheme.cellTitleColor
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        roundedBackground.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BalanceTheme.cellBigMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(BalanceTheme.rateTopMargin)
        }
        rateLabel.font = BalanceTheme.rateFont
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        roundedBackground.addSubview(coinValueLabel)
        coinValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.nameLabel.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
            maker.centerY.equalTo(self.nameLabel.snp.centerY)
        }
        coinValueLabel.font = BalanceTheme.coinValueFont
        coinValueLabel.textColor = BalanceTheme.coinValueColor
        coinValueLabel.textAlignment = .right

        roundedBackground.addSubview(currencyValueLabel)
        currencyValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.rateLabel.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
            maker.centerY.equalTo(self.rateLabel.snp.centerY)
        }
        currencyValueLabel.font = BalanceTheme.currencyValueFont
        currencyValueLabel.textAlignment = .right

        syncSpinner.backgroundColor = BalanceTheme.spinnerBackgroundColor
        syncSpinner.layer.cornerRadius = BalanceTheme.spinnerSideSize / 2
        roundedBackground.addSubview(syncSpinner)
        syncSpinner.snp.makeConstraints { maker in
            maker.center.equalTo(self.coinIconImageView.snp.center)
            maker.size.equalTo(BalanceTheme.spinnerSideSize)
        }

        failedImageView.image = UIImage(named: "Balance Sync Failed Icon")
        roundedBackground.addSubview(failedImageView)
        failedImageView.snp.makeConstraints { maker in
            maker.center.equalTo(self.coinIconImageView.snp.center)
        }

        roundedBackground.addSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BalanceTheme.cellSmallMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(BalanceTheme.buttonsTopMargin)
            maker.height.equalTo(BalanceTheme.buttonsHeight)
        }
        receiveButton.onTap = { [weak self] in self?.receive() }
        receiveButton.backgrounds = ButtonTheme.greenBackgroundOnDarkBackgroundDictionary
        receiveButton.cornerRadius = BalanceTheme.buttonCornerRadius
        receiveButton.titleLabel.text = "balance.deposit".localized

        roundedBackground.addSubview(payButton)
        payButton.snp.makeConstraints { maker in
            maker.leading.equalTo(receiveButton.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(BalanceTheme.buttonsTopMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellSmallMargin)
            maker.height.equalTo(BalanceTheme.buttonsHeight)
            maker.width.equalTo(receiveButton)
        }
        payButton.onTap = { [weak self] in self?.pay() }
        payButton.backgrounds = ButtonTheme.yellowBackgroundOnDarkBackgroundDictionary
        payButton.textColors = ButtonTheme.textColorOnWhiteBackgroundDictionary
        payButton.cornerRadius = BalanceTheme.buttonCornerRadius
        payButton.titleLabel.text = "balance.send".localized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: BalanceViewItem, selected: Bool, animated: Bool = false, onReceive: @escaping (() -> ()), onPay: @escaping (() -> ())) {
        self.onPay = onPay
        self.onReceive = onReceive

        bindView(item: item, selected: selected, animated: animated)

        if case let .syncing(progressSubject) = item.state, let subject = progressSubject {
            progressDisposable = subject
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] progress, date in
                        self?.bind(progress: progress, date: date)
                    })
        } else {
            syncSpinner.set(progress: 1)
        }
    }

    func bindView(item: BalanceViewItem, selected: Bool, animated: Bool = false) {
        expanded = selected

        coinIconImageView.bind(coin: item.coin)

        receiveButton.set(hidden: !selected, animated: animated, duration: BalanceTheme.buttonsAnimationDuration)
        payButton.set(hidden: !selected, animated: animated, duration: BalanceTheme.buttonsAnimationDuration)

        if case .synced = item.state {
            coinIconImageView.isHidden = false
            payButton.state = .active
        } else {
            coinIconImageView.isHidden = true
            payButton.state = .disabled
        }

        nameLabel.text = item.coin.title.localized

        if let progressDateString = progressDateString, selected {
            rateLabel.text = progressDateString
            rateLabel.textColor = BalanceTheme.rateColor
        } else if let value = item.exchangeValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, shortFractionLimit: 100) {
            rateLabel.text = "balance.rate_per_coin".localized(formattedValue, item.coinValue.coinCode)
            rateLabel.textColor = item.rateExpired ? BalanceTheme.rateExpiredColor : BalanceTheme.rateColor
        } else {
            rateLabel.text = " " // space required for constraints
        }

        if let value = item.currencyValue, value.value != 0 {
            currencyValueLabel.text = ValueFormatter.instance.format(currencyValue: value)
            let nonZeroBalanceTextColor = item.rateExpired ? BalanceTheme.nonZeroBalanceExpiredTextColor : BalanceTheme.nonZeroBalanceTextColor
            currencyValueLabel.textColor = value.value > 0 ? nonZeroBalanceTextColor : BalanceTheme.zeroBalanceTextColor
        } else {
            currencyValueLabel.text = nil
        }

        coinValueLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue)

        if case .notSynced = item.state {
            failedImageView.isHidden = false
        } else {
            failedImageView.isHidden = true
        }

        if case .syncing = item.state {
            syncSpinner.isHidden = false
            syncSpinner.startAnimating()
        } else {
            syncSpinner.isHidden = true
        }
    }

    private func bind(progress: Double, date: Date?) {
        syncSpinner.set(progress: max(BalanceCell.minimumProgress, Float(progress)))
        progressDateString = date.map { "balance.synced_through".localized(DateHelper.instance.formatSyncedThroughDate(from: $0)) }

        if let progressDateString = progressDateString, expanded {
            rateLabel.text = progressDateString
        }
    }

    func unbind() {
        progressDisposable?.dispose()
        progressDisposable = nil
        progressDateString = nil
    }

    func receive() {
        onReceive?()
    }

    func pay() {
        onPay?()
    }

    deinit {
    }

}
