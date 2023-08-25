import UIKit
import ThemeKit
import SnapKit
import ComponentKit

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

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: BalanceViewItem, onTapError: (() -> ())?) {
        topView.bind(viewItem: viewItem.topViewItem, onTapError: onTapError)
        topView.layoutIfNeeded()
    }

    static func height() -> CGFloat {
        return BalanceTopView.height + margins.height
    }

}
