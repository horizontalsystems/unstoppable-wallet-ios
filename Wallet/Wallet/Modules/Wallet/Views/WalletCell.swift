import UIKit
import GrouviHUD

class WalletCell: UITableViewCell {

    var roundedBackground = UIView()

    var nameLabel = UILabel()
    var valueLabel = UILabel()
    var coinAmountLabel = UILabel()
    var spinnerView = HUDProgressView(strokeLineWidth: WalletTheme.spinnerLineWidth, radius: WalletTheme.spinnerSideSize / 2 - WalletTheme.spinnerLineWidth / 2, strokeColor: UIColor.cryptoGray)

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

        roundedBackground.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WalletTheme.cellBigMargin)
            maker.top.equalToSuperview().offset(WalletTheme.cellSmallMargin)
        }
        nameLabel.font = WalletTheme.cellTitleFont
        nameLabel.textColor = WalletTheme.cellTitleColor

        roundedBackground.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WalletTheme.cellBigMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(WalletTheme.cellSmallMargin)
        }
        valueLabel.font = WalletTheme.cellSubtitleFont

        roundedBackground.addSubview(coinAmountLabel)
        coinAmountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.valueLabel.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.centerY.equalTo(self.valueLabel)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellBigMargin)
        }
        coinAmountLabel.font = WalletTheme.cellTitleFont
        coinAmountLabel.textColor = WalletTheme.cellTitleColor
        coinAmountLabel.textAlignment = .right

        roundedBackground.addSubview(spinnerView)
        spinnerView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(WalletTheme.cellSmallMargin)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellBigMargin)
            maker.size.equalTo(WalletTheme.spinnerSideSize)
        }

        roundedBackground.addSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WalletTheme.cellSmallMargin)
            maker.top.equalTo(self.coinAmountLabel.snp.bottom).offset(WalletTheme.buttonsTopMargin)
            maker.height.equalTo(WalletTheme.buttonsHeight)
        }
        receiveButton.onTap = { [weak self] in self?.receive() }
        receiveButton.backgrounds = ButtonTheme.greenBackgroundOnDarkBackgroundDictionary
        receiveButton.cornerRadius = WalletTheme.buttonCornerRadius
        receiveButton.titleLabel.text = "wallet.deposit".localized

        roundedBackground.addSubview(payButton)
        payButton.snp.makeConstraints { maker in
            maker.leading.equalTo(receiveButton.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.top.equalTo(self.coinAmountLabel.snp.bottom).offset(WalletTheme.buttonsTopMargin)
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

    func bind(balance: WalletBalanceViewItem, showSpinner: Bool, selected: Bool, animated: Bool = false, onReceive: @escaping (() -> ()), onPay: @escaping (() -> ())) {
        self.onPay = onPay
        self.onReceive = onReceive
        spinnerView.isHidden = !showSpinner
        if showSpinner {
            spinnerView.startAnimating()
        } else {
            spinnerView.stopAnimating()
        }

        bindView(balance: balance, selected: selected, animated: animated)
    }

    func bindView(balance: WalletBalanceViewItem, selected: Bool, animated: Bool = false) {
        receiveButton.set(hidden: !selected, animated: animated, duration: WalletTheme.buttonsAnimationDuration)
        payButton.set(hidden: !selected, animated: animated, duration: WalletTheme.buttonsAnimationDuration)

        nameLabel.text = "\(balance.coinValue.coin.name) (\(balance.coinValue.coin.code))"
        valueLabel.text = CurrencyHelper.instance.formattedValue(for: balance.currencyValue)
        valueLabel.textColor = balance.currencyValue.value > 0 ? WalletTheme.nonZeroBalanceTextColor : WalletTheme.zeroBalanceTextColor
        coinAmountLabel.text = CoinValueHelper.formattedAmount(for: balance.coinValue)
    }

    func receive() {
        onReceive?()
    }

    func pay() {
        onPay?()
    }

}
