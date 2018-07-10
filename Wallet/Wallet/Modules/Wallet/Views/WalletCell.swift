import UIKit

class WalletCell: UITableViewCell {

    var roundedBackground = UIView()

    var nameLabel = UILabel()
    var valueLabel = UILabel()
    var exchangeLabel = UILabel()
    var coinLabel = UILabel()

    var receiveButton = Button()
    var payButton = Button()

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
            maker.leading.equalTo(self.nameLabel.snp.trailing).offset(WalletTheme.cellBigMargin)
            maker.top.equalToSuperview().offset(WalletTheme.cellSmallMargin)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellBigMargin)
        }
        valueLabel.font = WalletTheme.cellTitleFont
        valueLabel.textColor = WalletTheme.cellTitleColor
        valueLabel.textAlignment = .right

        roundedBackground.addSubview(exchangeLabel)
        exchangeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WalletTheme.cellBigMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(WalletTheme.cellBigMargin)
        }
        exchangeLabel.font = WalletTheme.cellSubtitleFont
        exchangeLabel.textColor = WalletTheme.cellSubtitleColor

        roundedBackground.addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.exchangeLabel.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.top.equalTo(self.valueLabel.snp.bottom).offset(WalletTheme.cellBigMargin)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellBigMargin)
        }
        coinLabel.font = WalletTheme.cellSubtitleFont
        coinLabel.textColor = WalletTheme.cellSubtitleColor
        coinLabel.textAlignment = .right

        roundedBackground.addSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WalletTheme.cellSmallMargin)
            maker.top.equalTo(self.exchangeLabel.snp.bottom).offset(WalletTheme.buttonsTopMargin)
            maker.height.equalTo(WalletTheme.buttonsHeight)
        }
        receiveButton.titleLabel?.font = WalletTheme.cellButtonFont
        receiveButton.backgroundColor = WalletTheme.receiveButtonBackground
        receiveButton.setTitleColor(WalletTheme.buttonsTextColor, for: .normal)
        receiveButton.setTitleColor(WalletTheme.selectedButtonsTextColor, for: .highlighted)
        receiveButton.cornerRadius = WalletTheme.buttonCornerRadius
        receiveButton.setTitle("wallet.receive".localized, for: .normal)
        receiveButton.addTarget(self, action: #selector(receive), for: .touchUpInside)

        roundedBackground.addSubview(payButton)
        payButton.snp.makeConstraints { maker in
            maker.leading.equalTo(receiveButton.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.top.equalTo(self.coinLabel.snp.bottom).offset(WalletTheme.buttonsTopMargin)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellSmallMargin)
            maker.height.equalTo(WalletTheme.buttonsHeight)
            maker.width.equalTo(receiveButton)
        }
        payButton.titleLabel?.font = WalletTheme.cellButtonFont
        payButton.backgroundColor = WalletTheme.payButtonBackground
        payButton.setTitleColor(WalletTheme.buttonsTextColor, for: .normal)
        payButton.setTitleColor(WalletTheme.selectedButtonsTextColor, for: .highlighted)
        payButton.cornerRadius = WalletTheme.buttonCornerRadius
        payButton.setTitle("wallet.pay".localized, for: .normal)
        payButton.addTarget(self, action: #selector(pay), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(balance: WalletBalanceViewItem, selected: Bool, animated: Bool = false, onReceive: @escaping (() -> ()), onPay: @escaping (() -> ())) {
        self.onPay = onPay
        self.onReceive = onReceive

        bindView(balance: balance, selected: selected, animated: animated)
    }

    func bindView(balance: WalletBalanceViewItem, selected: Bool, animated: Bool = false) {
        receiveButton.set(hidden: !selected, animated: animated, duration: WalletTheme.buttonsAnimationDuration)
        payButton.set(hidden: !selected, animated: animated, duration: WalletTheme.buttonsAnimationDuration)

        nameLabel.text = balance.coinValue.coin.name
        valueLabel.text = CurrencyHelper.instance.formattedValue(for: balance.currencyValue)
        exchangeLabel.text = CurrencyHelper.instance.formattedValue(for: balance.exchangeValue)
        coinLabel.text = balance.coinValue.formattedAmount
    }

    @objc func receive() {
        onReceive?()
    }

    @objc func pay() {
        onPay?()
    }

}
