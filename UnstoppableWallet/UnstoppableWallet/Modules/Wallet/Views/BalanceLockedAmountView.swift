import UIKit
import SnapKit

class BalanceLockedAmountView: UIView {
    static let height: CGFloat = 36

    private let coinValueLabel = UILabel()
    private let currencyValueLabel = UILabel()

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        let wrapperView = UIView()

        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.height.equalTo(Self.height)
        }

        let separatorView = UIView()

        wrapperView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel20

        let iconImageView = UIImageView()

        wrapperView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(16)
        }

        iconImageView.image = UIImage(named: "lock_16")
        iconImageView.tintColor = .themeGray

        wrapperView.addSubview(coinValueLabel)
        coinValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(CGFloat.margin4)
            maker.centerY.equalToSuperview()
        }

        coinValueLabel.font = .subhead2

        wrapperView.addSubview(currencyValueLabel)
        currencyValueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinValueLabel.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        currencyValueLabel.font = .subhead2
        currencyValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: BalanceLockedAmountViewItem) {
        coinValueLabel.text = viewItem.coinValue.text
        coinValueLabel.textColor = viewItem.coinValue.dimmed ? .themeGray50 : .themeGray

        if let currencyValue = viewItem.currencyValue {
            currencyValueLabel.text = currencyValue.text
            currencyValueLabel.textColor = currencyValue.dimmed ? .themeGray50 : .themeLeah
        } else {
            currencyValueLabel.text = nil
        }
    }

}
