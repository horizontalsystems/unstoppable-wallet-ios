import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class BalanceCell: UITableViewCell {
    private static let margins = UIEdgeInsets(top: .margin8, left: .margin16, bottom: 0, right: .margin16)

    private let cardView = CardView(insets: .zero)

    private let topView = BalanceTopView()

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
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: BalanceViewItem, onTapError: (() -> Void)?) {
        topView.bind(viewItem: viewItem.topViewItem, onTapError: onTapError)
        topView.layoutIfNeeded()
    }

    static func height() -> CGFloat {
        BalanceTopView.height + margins.height
    }
}
