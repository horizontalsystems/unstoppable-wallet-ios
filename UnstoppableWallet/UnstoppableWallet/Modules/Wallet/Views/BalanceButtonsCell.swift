
import SnapKit

import UIKit

class BalanceButtonsCell: UITableViewCell {
    static let height = BalanceButtonsView.height

    private let buttonsView = BalanceButtonsView()
    var actions: [WalletModule.Button: () -> Void] = [:]

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(buttonsView)
        buttonsView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not implemented")
    }

    func bind(buttons: [WalletModule.Button: ButtonState]) {
        buttonsView.bind(
            buttons: buttons,
            sendAction: actions[.send],
            receiveAction: actions[.receive],
            swapAction: actions[.swap],
            chartAction: actions[.chart]
        )
    }
}
