import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class WalletHeaderCell: UITableViewCell {
    internal var amountView = HeaderAmountView()
    internal let buttonsView = BalanceButtonsView()

    var actions: [WalletModule.Button: () -> ()] = [:]

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(amountView)
        amountView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        contentView.addSubview(buttonsView)
        buttonsView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            make.top.equalTo(amountView.snp.bottom)
            make.height.equalTo(BalanceButtonsView.height)
        }

        let separatorView = UIView()
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel20
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    var onTapAmount: (() -> ())? {
        get { amountView.onTapAmount }
        set { amountView.onTapAmount = newValue }
    }

    var onTapConvertedAmount: (() -> ())? {
        get { amountView.onTapConvertedAmount }
        set { amountView.onTapConvertedAmount = newValue }
    }

    func bind(viewItem: WalletModule.HeaderViewItem) {
        amountView.set(amountText: viewItem.amount, expired: viewItem.amountExpired)
        amountView.set(convertedAmountText: viewItem.convertedValue, expired: viewItem.convertedValueExpired)
        buttonsView.bind(
                buttons: viewItem.buttons,
                sendAction: actions[.send],
                withdrawAction: actions[.withdraw],
                receiveAction: actions[.receive],
                depositAction: actions[.deposit],
                swapAction: actions[.swap],
                chartAction: actions[.chart]
        )
    }

}

extension WalletHeaderCell {

    static func height(viewItem: WalletModule.HeaderViewItem?) -> CGFloat {
        guard let viewItem else {
            return HeaderAmountView.height
        }

        var buttonsHidden = viewItem.buttons.isEmpty
        if !viewItem.buttons.isEmpty {
            buttonsHidden = viewItem.buttons.allSatisfy { key, value in value == .hidden }
        }
        return HeaderAmountView.height + (buttonsHidden ? 0 : BalanceButtonsView.height)
    }

}
