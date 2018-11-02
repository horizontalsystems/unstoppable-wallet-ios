import UIKit
import GrouviExtensions
import GrouviHUD
import RxSwift

class WalletCell: UITableViewCell {
    var progressDisposable: Disposable?

    var roundedBackground = UIView()

    var coinIconImageView = TintImageView(image: nil, tintColor: WalletTheme.coinIconTintColor, selectedTintColor: WalletTheme.coinIconTintColor)
    var nameLabel = UILabel()
    var rateLabel = UILabel()
    var rateSpinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
    var currencyValueLabel = UILabel()
    var coinValueLabel = UILabel()

    var syncSpinner = HUDProgressView(strokeLineWidth: WalletTheme.spinnerLineWidth, radius: WalletTheme.spinnerSideSize / 2 - WalletTheme.spinnerLineWidth / 2, strokeColor: UIColor.cryptoGray)
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
            maker.top.equalToSuperview().offset(WalletTheme.cellPadding)
            maker.leadingMargin.trailingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.bottom.equalToSuperview()
        }
        roundedBackground.backgroundColor = WalletTheme.roundedBackgroundColor
        roundedBackground.clipsToBounds = true
        roundedBackground.layer.cornerRadius = WalletTheme.roundedBackgroundCornerRadius

        roundedBackground.addSubview(coinIconImageView)
        coinIconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WalletTheme.cellBigMargin)
            maker.top.equalToSuperview().offset(WalletTheme.cellSmallMargin)
            maker.size.equalTo(WalletTheme.coinIconSide)
        }

        roundedBackground.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.coinIconImageView.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.top.equalToSuperview().offset(WalletTheme.nameTopMargin)
        }
        nameLabel.font = WalletTheme.cellTitleFont
        nameLabel.textColor = WalletTheme.cellTitleColor
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        roundedBackground.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WalletTheme.cellBigMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(WalletTheme.valueTopMargin)
        }
        rateLabel.font = WalletTheme.cellSubtitleFont
        rateLabel.textColor = WalletTheme.rateColor
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        roundedBackground.addSubview(rateSpinner)
        rateSpinner.snp.makeConstraints { maker in
            maker.leading.equalTo(self.rateLabel.snp.trailing).offset(WalletTheme.rateSpinnerLeftMargin)
            maker.centerY.equalTo(self.rateLabel.snp.centerY)
            maker.size.equalTo(WalletTheme.rateSpinnerSize)
        }
        rateSpinner.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
        rateSpinner.color = WalletTheme.rateColor

        roundedBackground.addSubview(currencyValueLabel)
        currencyValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.nameLabel.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellBigMargin)
            maker.centerY.equalTo(self.nameLabel.snp.centerY)
        }
        currencyValueLabel.font = WalletTheme.cellSubtitleFont
        currencyValueLabel.textAlignment = .right

        roundedBackground.addSubview(coinValueLabel)
        coinValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.rateSpinner.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.bottom.equalTo(self.rateLabel).offset(WalletTheme.coinLabelVerticalOffset)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellBigMargin)
        }
        coinValueLabel.font = WalletTheme.cellTitleFont
        coinValueLabel.textColor = WalletTheme.cellTitleColor
        coinValueLabel.textAlignment = .right

        roundedBackground.addSubview(syncLabel)
        syncLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.rateSpinner.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.centerY.equalTo(self.rateLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellBigMargin)
        }
        syncLabel.font = .cryptoCaption3
        syncLabel.textColor = WalletTheme.rateColor
        syncLabel.textAlignment = .right

        roundedBackground.addSubview(syncSpinner)
        syncSpinner.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellBigMargin)
            maker.centerY.equalTo(self.nameLabel.snp.centerY)
            maker.size.equalTo(WalletTheme.spinnerSideSize)
        }

        roundedBackground.addSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WalletTheme.cellSmallMargin)
            maker.top.equalTo(self.coinValueLabel.snp.bottom).offset(WalletTheme.buttonsTopMargin)
            maker.height.equalTo(WalletTheme.buttonsHeight)
        }
        receiveButton.onTap = { [weak self] in self?.receive() }
        receiveButton.backgrounds = ButtonTheme.greenBackgroundOnDarkBackgroundDictionary
        receiveButton.cornerRadius = WalletTheme.buttonCornerRadius
        receiveButton.titleLabel.text = "wallet.deposit".localized

        roundedBackground.addSubview(payButton)
        payButton.snp.makeConstraints { maker in
            maker.leading.equalTo(receiveButton.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.top.equalTo(self.coinValueLabel.snp.bottom).offset(WalletTheme.buttonsTopMargin)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellSmallMargin)
            maker.height.equalTo(WalletTheme.buttonsHeight)
            maker.width.equalTo(receiveButton)
        }
        payButton.onTap = { [weak self] in self?.pay() }
        payButton.backgrounds = ButtonTheme.yellowBackgroundOnDarkBackgroundDictionary
        payButton.cornerRadius = WalletTheme.buttonCornerRadius
        payButton.titleLabel.text = "wallet.send".localized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: WalletViewItem, selected: Bool, animated: Bool = false, onReceive: @escaping (() -> ()), onPay: @escaping (() -> ())) {
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

    func bindView(item: WalletViewItem, selected: Bool, animated: Bool = false) {
        var synced = false
        if case .synced = item.state {
            synced = true
        }

        coinIconImageView.image = UIImage(named: "\(item.coinValue.coin) Icon")

        receiveButton.set(hidden: !selected, animated: animated, duration: WalletTheme.buttonsAnimationDuration)
        payButton.set(hidden: !selected, animated: animated, duration: WalletTheme.buttonsAnimationDuration)

        nameLabel.text = "coin.\(item.coinValue.coin)".localized

        if let value = item.exchangeValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value) {
            rateLabel.text = "wallet.rate_per_coin".localized(formattedValue, item.coinValue.coin)
        } else {
            rateLabel.text = "wallet.loading_rate".localized
        }

        if item.rateExpired {
            rateSpinner.startAnimating()
        } else {
            rateSpinner.stopAnimating()
        }

        if synced, let value = item.currencyValue {
            currencyValueLabel.text = ValueFormatter.instance.format(currencyValue: value)
            currencyValueLabel.textColor = value.value > 0 ? WalletTheme.nonZeroBalanceTextColor : WalletTheme.zeroBalanceTextColor
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
        syncLabel.text = "wallet.syncing_percent".localized("\(Int(progress * 100))%")
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
