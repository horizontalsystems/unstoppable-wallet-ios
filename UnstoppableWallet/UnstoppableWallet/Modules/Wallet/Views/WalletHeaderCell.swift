import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class WalletHeaderCell: UITableViewCell {
    var amountView = HeaderAmountView()
    let buttonsView = BalanceButtonsView()

    var actions: [WalletModule.Button: () -> Void] = [:]

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
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not implemented")
    }

    var onTapAmount: (() -> Void)? {
        get { amountView.onTapAmount }
        set { amountView.onTapAmount = newValue }
    }

    var onTapConvertedAmount: (() -> Void)? {
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
            buttonsHidden = viewItem.buttons.allSatisfy { _, value in value == .hidden }
        }
        return HeaderAmountView.height + (buttonsHidden ? 0 : BalanceButtonsView.height)
    }
}
