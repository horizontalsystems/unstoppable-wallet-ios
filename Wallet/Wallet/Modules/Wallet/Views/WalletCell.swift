import UIKit
import GrouviExtensions
import GrouviHUD
import RxSwift

class WalletCell: UITableViewCell {
    var progressDisposable: Disposable?

    var roundedBackground = UIView()

    var coinIconImageView = TintImageView(image: nil, tintColor: WalletTheme.coinIconTintColor, selectedTintColor: WalletTheme.coinIconTintColor)
    var nameLabel = UILabel()
    var valueLabel = UILabel()
    var coinAmountLabel = UILabel()

    var spinnerView = HUDProgressView(progress: 0.01, strokeLineWidth: WalletTheme.spinnerLineWidth, radius: WalletTheme.spinnerSideSize / 2 - WalletTheme.spinnerLineWidth / 2, strokeColor: UIColor.cryptoGray)
    var smoothChanger: SmoothValueChanger?

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

        roundedBackground.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WalletTheme.cellBigMargin)
            maker.top.equalTo(self.nameLabel.snp.bottom).offset(WalletTheme.valueTopMargin)
        }
        valueLabel.font = WalletTheme.cellSubtitleFont

        roundedBackground.addSubview(coinAmountLabel)
        coinAmountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.valueLabel.snp.trailing).offset(WalletTheme.cellSmallMargin)
            maker.bottom.equalTo(self.valueLabel).offset(WalletTheme.coinLabelVerticalOffset)
            maker.trailing.equalToSuperview().offset(-WalletTheme.cellBigMargin)
        }
        coinAmountLabel.font = WalletTheme.cellTitleFont
        coinAmountLabel.textColor = WalletTheme.cellTitleColor
        coinAmountLabel.textAlignment = .right

        smoothChanger = SmoothValueChanger(initialValue: 0, fullChangeTime: 0.5, onChangeValue: { [weak self] progress in
            self?.spinnerView.set(progress: progress)
        }, onFinishChanging: { [weak self] progress in
            if progress >= 1 {
                self?.spinnerView.isHidden = true
            }
        })
        spinnerView.isHidden = true
        spinnerView.set(valueChanger: smoothChanger)
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

    func bind(balance: WalletBalanceViewItem, selected: Bool, animated: Bool = false, onReceive: @escaping (() -> ()), onPay: @escaping (() -> ())) {
        self.onPay = onPay
        self.onReceive = onReceive

        let spinnerView = self.spinnerView
        progressDisposable = balance.progressSubject?
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] progress in
                    if progress < 1, spinnerView.isHidden {
                        spinnerView.startAnimating()
                        spinnerView.isHidden = false
                    }
                    self?.smoothChanger?.set(value: Float(progress))
                })
        bindView(balance: balance, selected: selected, animated: animated)
    }

    func bindView(balance: WalletBalanceViewItem, selected: Bool, animated: Bool = false) {
        coinIconImageView.image = UIImage(named: "\(balance.coinValue.coin) Icon")

        receiveButton.set(hidden: !selected, animated: animated, duration: WalletTheme.buttonsAnimationDuration)
        payButton.set(hidden: !selected, animated: animated, duration: WalletTheme.buttonsAnimationDuration)

        nameLabel.text = "\(balance.coinValue.coin) (\(balance.coinValue.coin))"
        valueLabel.text = balance.currencyValue.map { CurrencyHelper.instance.formattedValue(for: $0) } ?? "n/a"
        valueLabel.textColor = (balance.currencyValue?.value ?? 0) > 0 ? WalletTheme.nonZeroBalanceTextColor : WalletTheme.zeroBalanceTextColor
        coinAmountLabel.text = "\(balance.coinValue.value)"
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

}
