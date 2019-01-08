import UIKit
import GrouviExtensions
import GrouviHUD
import RxSwift

class BalanceCell: UITableViewCell {
    var progressDisposable: Disposable?

    var roundedBackground = UIView()

    var coinIconImageView = TintImageView(image: nil, tintColor: BalanceTheme.coinIconTintColor, selectedTintColor: BalanceTheme.coinIconTintColor)
    var nameLabel = UILabel()
    var rateLabel = UILabel()
    var currencyValueLabel = UILabel()
    var coinValueLabel = UILabel()

    var syncSpinner = HUDProgressView(strokeLineWidth: BalanceTheme.spinnerLineWidth, radius: BalanceTheme.spinnerSideSize / 2 - BalanceTheme.spinnerLineWidth / 2, strokeColor: UIColor.cryptoGray)
    var syncLabel = UILabel()

    var failedImageView = UIImageView()

    var refreshImageView = TintImageView(image: UIImage(named: "Refresh Icon"), tintColor: BalanceTheme.refreshButtonColor, selectedTintColor: BalanceTheme.refreshButtonColorHighlighted)
    var refreshButton = RespondView()

    var receiveButton = RespondButton()
    var payButton = RespondButton()

    var onRefresh: (() -> ())?
    var onPay: (() -> ())?
    var onReceive: (() -> ())?

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

        roundedBackground.addSubview(refreshButton)
        refreshButton.snp.makeConstraints { maker in
            maker.leading.equalTo(self.nameLabel.snp.trailing)
            maker.centerY.equalTo(self.nameLabel.snp.centerY)
            maker.width.equalTo(BalanceTheme.refreshButtonSize)
            maker.height.equalTo(BalanceTheme.refreshButtonSize)
        }
        refreshButton.handleTouch = { [weak self] in self?.refresh() }
        refreshButton.cornerRadius = BalanceTheme.buttonCornerRadius

        refreshButton.addSubview(refreshImageView)
        refreshImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        refreshButton.delegate = refreshImageView

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
            maker.leading.equalTo(self.refreshButton.snp.trailing).offset(BalanceTheme.cellSmallMargin).priority(.high)
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

        roundedBackground.addSubview(syncLabel)
        syncLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.rateLabel.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.centerY.equalTo(self.rateLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
        }
        syncLabel.font = .cryptoCaption3
        syncLabel.textColor = BalanceTheme.rateColor
        syncLabel.textAlignment = .right

        roundedBackground.addSubview(syncSpinner)
        syncSpinner.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
            maker.leading.equalTo(self.refreshButton.snp.trailing).offset(BalanceTheme.cellSmallMargin).priority(.medium)
            maker.centerY.equalTo(self.nameLabel.snp.centerY)
            maker.size.equalTo(BalanceTheme.spinnerSideSize)
        }

        failedImageView.image = UIImage(named: "Attention Icon")
        roundedBackground.addSubview(failedImageView)
        failedImageView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
            maker.centerY.equalTo(self.nameLabel.snp.centerY)
            maker.size.equalTo(BalanceTheme.spinnerSideSize)
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

    func bind(item: BalanceViewItem, selected: Bool, animated: Bool = false, onRefresh: @escaping (() -> ()), onReceive: @escaping (() -> ()), onPay: @escaping (() -> ())) {
        self.onRefresh = onRefresh
        self.onPay = onPay
        self.onReceive = onReceive

        bindView(item: item, selected: selected, animated: animated)

        if case let .syncing(progressSubject) = item.state, let subject = progressSubject {
            progressDisposable = subject
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] progress in
                        self?.bind(progress: progress)
                    })
        } else {
            syncLabel.text = nil
        }
    }

    func bindView(item: BalanceViewItem, selected: Bool, animated: Bool = false) {
        coinIconImageView.image = UIImage(named: "\(item.coinValue.coinCode) Icon")

        receiveButton.set(hidden: !selected, animated: animated, duration: BalanceTheme.buttonsAnimationDuration)
        payButton.set(hidden: !selected, animated: animated, duration: BalanceTheme.buttonsAnimationDuration)

        if case .synced = item.state {
            payButton.state = .active
        } else {
            payButton.state = .disabled
        }

        nameLabel.text = "coin.\(item.coinValue.coinCode)".localized

        if let value = item.exchangeValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, shortFractionLimit: 100) {
            rateLabel.text = "balance.rate_per_coin".localized(formattedValue, item.coinValue.coinCode)
        } else {
            rateLabel.text = " " // space required for constraints
        }

        rateLabel.textColor = item.rateExpired ? BalanceTheme.rateExpiredColor : BalanceTheme.rateColor

        if case .synced = item.state, let value = item.currencyValue, value.value != 0 {
            currencyValueLabel.text = ValueFormatter.instance.format(currencyValue: value)
            let nonZeroBalanceTextColor = item.rateExpired ? BalanceTheme.nonZeroBalanceExpiredTextColor : BalanceTheme.nonZeroBalanceTextColor
            currencyValueLabel.textColor = value.value > 0 ? nonZeroBalanceTextColor : BalanceTheme.zeroBalanceTextColor
        } else {
            currencyValueLabel.text = nil
        }

        if case .synced = item.state {
            coinValueLabel.isHidden = false
        } else {
            coinValueLabel.isHidden = true
        }
        coinValueLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue)

        if case .syncing = item.state {
            syncLabel.isHidden = false
            syncSpinner.isHidden = false
            syncSpinner.startAnimating()
        } else {
            syncLabel.isHidden = true
            syncSpinner.isHidden = true
        }

        if case .notSynced = item.state {
            failedImageView.isHidden = false
        } else {
            failedImageView.isHidden = true
        }

        refreshButton.snp.updateConstraints { maker in
            maker.width.equalTo(item.refreshVisible ? BalanceTheme.refreshButtonSize : 0)
        }
    }

    private func bind(progress: Double) {
        syncLabel.text = "\(Int(progress * 100))%"
    }

    func unbind() {
        progressDisposable?.dispose()
        progressDisposable = nil
    }

    func refresh() {
        onRefresh?()
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
