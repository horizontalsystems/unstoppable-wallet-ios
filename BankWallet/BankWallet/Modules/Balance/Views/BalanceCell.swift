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
    var rateSpinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
    var currencyValueLabel = UILabel()
    var coinValueLabel = UILabel()

    var syncSpinner = HUDProgressView(strokeLineWidth: BalanceTheme.spinnerLineWidth, radius: BalanceTheme.spinnerSideSize / 2 - BalanceTheme.spinnerLineWidth / 2, strokeColor: UIColor.cryptoGray)
    var syncLabel = UILabel()

    var receiveButton = RespondButton()
    var payButton = RespondButton()

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
            maker.top.equalToSuperview().offset(BalanceTheme.nameTopMargin)
        }
        nameLabel.font = BalanceTheme.cellTitleFont
        nameLabel.textColor = BalanceTheme.cellTitleColor
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        roundedBackground.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BalanceTheme.cellBigMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(BalanceTheme.valueTopMargin)
        }
        rateLabel.font = BalanceTheme.cellSubtitleFont
        rateLabel.textColor = BalanceTheme.rateColor
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        roundedBackground.addSubview(rateSpinner)
        rateSpinner.snp.makeConstraints { maker in
            maker.leading.equalTo(self.rateLabel.snp.trailing).offset(BalanceTheme.rateSpinnerLeftMargin)
            maker.centerY.equalTo(self.rateLabel.snp.centerY)
            maker.size.equalTo(BalanceTheme.rateSpinnerSize)
        }
        rateSpinner.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
        rateSpinner.color = BalanceTheme.rateColor

        roundedBackground.addSubview(currencyValueLabel)
        currencyValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.nameLabel.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
            maker.centerY.equalTo(self.nameLabel.snp.centerY)
        }
        currencyValueLabel.font = BalanceTheme.cellSubtitleFont
        currencyValueLabel.textAlignment = .right

        roundedBackground.addSubview(coinValueLabel)
        coinValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.rateSpinner.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.bottom.equalTo(self.rateLabel).offset(BalanceTheme.coinLabelVerticalOffset)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
        }
        coinValueLabel.font = BalanceTheme.cellTitleFont
        coinValueLabel.textColor = BalanceTheme.cellTitleColor
        coinValueLabel.textAlignment = .right

        roundedBackground.addSubview(syncLabel)
        syncLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.rateSpinner.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.centerY.equalTo(self.rateLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
        }
        syncLabel.font = .cryptoCaption3
        syncLabel.textColor = BalanceTheme.rateColor
        syncLabel.textAlignment = .right

        roundedBackground.addSubview(syncSpinner)
        syncSpinner.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellBigMargin)
            maker.centerY.equalTo(self.nameLabel.snp.centerY)
            maker.size.equalTo(BalanceTheme.spinnerSideSize)
        }

        roundedBackground.addSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BalanceTheme.cellSmallMargin)
            maker.top.equalTo(self.coinValueLabel.snp.bottom).offset(BalanceTheme.buttonsTopMargin)
            maker.height.equalTo(BalanceTheme.buttonsHeight)
        }
        receiveButton.onTap = { [weak self] in self?.receive() }
        receiveButton.backgrounds = ButtonTheme.greenBackgroundOnDarkBackgroundDictionary
        receiveButton.cornerRadius = BalanceTheme.buttonCornerRadius
        receiveButton.titleLabel.text = "balance.deposit".localized

        roundedBackground.addSubview(payButton)
        payButton.snp.makeConstraints { maker in
            maker.leading.equalTo(receiveButton.snp.trailing).offset(BalanceTheme.cellSmallMargin)
            maker.top.equalTo(self.coinValueLabel.snp.bottom).offset(BalanceTheme.buttonsTopMargin)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.cellSmallMargin)
            maker.height.equalTo(BalanceTheme.buttonsHeight)
            maker.width.equalTo(receiveButton)
        }
        payButton.onTap = { [weak self] in self?.pay() }
        payButton.backgrounds = ButtonTheme.yellowBackgroundOnDarkBackgroundDictionary
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

        if case let .syncing(progressSubject) = item.state {
            progressDisposable = progressSubject
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] progress in
                        self?.bind(progress: progress)
                    })
        }
    }

    func bindView(item: BalanceViewItem, selected: Bool, animated: Bool = false) {
        var synced = false
        if case .synced = item.state {
            synced = true
        }

        coinIconImageView.image = UIImage(named: "\(item.coinValue.coin) Icon")

        receiveButton.set(hidden: !selected, animated: animated, duration: BalanceTheme.buttonsAnimationDuration)
        payButton.set(hidden: !selected, animated: animated, duration: BalanceTheme.buttonsAnimationDuration)

        nameLabel.text = "coin.\(item.coinValue.coin)".localized

        if let value = item.exchangeValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, shortFraction: true) {
            rateLabel.text = "balance.rate_per_coin".localized(formattedValue, item.coinValue.coin)
        } else {
            rateLabel.text = "balance.loading_rate".localized
        }

        if item.rateExpired {
            rateSpinner.startAnimating()
        } else {
            rateSpinner.stopAnimating()
        }

        if synced, let value = item.currencyValue {
            currencyValueLabel.text = ValueFormatter.instance.format(currencyValue: value)
            currencyValueLabel.textColor = value.value > 0 ? BalanceTheme.nonZeroBalanceTextColor : BalanceTheme.zeroBalanceTextColor
        } else {
            currencyValueLabel.text = nil
        }

        coinValueLabel.isHidden = !synced
        coinValueLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue)

        syncLabel.isHidden = synced

        if synced {
            syncSpinner.isHidden = true
        } else {
            syncSpinner.isHidden = false
            syncSpinner.startAnimating()
        }
    }

    private func bind(progress: Double) {
        syncLabel.text = "balance.syncing_percent".localized("\(Int(progress * 100))%")
    }

    func unbind() {
        progressDisposable?.dispose()
        progressDisposable = nil
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
