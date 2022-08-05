import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class BalanceCell: UITableViewCell {
    private static let margins = UIEdgeInsets(top: .margin4, left: .margin16, bottom: .margin4, right: .margin16)

    private let cardView = CardView(insets: .zero)

    private let topView = BalanceTopView()
    private let separatorView = UIView()
    private let lockedAmountView = BalanceLockedAmountView()
    private let buttonsView = BalanceButtonsView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(Self.margins)
        }

        cardView.contentView.addSubview(topView)
        topView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(BalanceTopView.height)
        }

        cardView.contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.top.equalTo(topView.snp.bottom)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel20

        cardView.contentView.addSubview(lockedAmountView)
        lockedAmountView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topView.snp.bottom)
            maker.height.equalTo(BalanceLockedAmountView.height)
        }

        cardView.contentView.addSubview(buttonsView)
        buttonsView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(lockedAmountView.snp.bottom)
            maker.height.equalTo(BalanceButtonsView.height)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: BalanceViewItem, animated: Bool = false, duration: TimeInterval = 0.2, onSend: @escaping () -> (), onReceive: @escaping () -> (), onSwap: @escaping () -> (), onChart: @escaping () -> (), onTapError: (() -> ())?) {
        topView.bind(viewItem: viewItem.topViewItem, onTapError: onTapError)
        topView.layoutIfNeeded()

        separatorView.set(hidden: viewItem.buttonsViewItem == nil, animated: animated, duration: duration)

        if let viewItem = viewItem.lockedAmountViewItem {
            lockedAmountView.bind(viewItem: viewItem)
            lockedAmountView.layoutIfNeeded()
        }

        lockedAmountView.set(hidden: viewItem.lockedAmountViewItem == nil, animated: animated, duration: duration)
        lockedAmountView.snp.updateConstraints { maker in
            maker.height.equalTo(viewItem.lockedAmountViewItem != nil ? BalanceLockedAmountView.height : 0)
        }

        if animated {
            UIView.animate(withDuration: duration) {
                self.contentView.layoutIfNeeded()
            }
        }

        if let viewItem = viewItem.buttonsViewItem {
            buttonsView.bind(viewItem: viewItem, sendAction: onSend, receiveAction: onReceive, swapAction: onSwap, chartAction: onChart)
        }
        buttonsView.set(hidden: viewItem.buttonsViewItem == nil, animated: animated, duration: duration)
    }

    static func height(viewItem: BalanceViewItem) -> CGFloat {
        var height: CGFloat = margins.height

        height += BalanceTopView.height

        if viewItem.lockedAmountViewItem != nil {
            height += BalanceLockedAmountView.height
        }

        if viewItem.buttonsViewItem != nil {
            height += BalanceButtonsView.height
        }

        return height
    }

}
