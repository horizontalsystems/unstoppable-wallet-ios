import UIKit
import SnapKit

class RestoreAccountCell: CardCell {
    private static let topPadding: CGFloat = 10
    private static let bottomPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin3x

    private let accountView = AccountDoubleLineCellView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clippingView.addSubview(accountView)
        accountView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(RestoreAccountCell.horizontalPadding)
            maker.top.equalToSuperview().offset(RestoreAccountCell.topPadding)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(accountType: AccountTypeViewItem) {
        accountView.bind(title: RestoreAccountCell.titleText(accountType: accountType), subtitle: accountType.coinCodes)
    }

}

extension RestoreAccountCell {

    static func titleText(accountType: AccountTypeViewItem) -> String {
        "restore.item_title".localized(accountType.title)
    }

    static func height(containerWidth: CGFloat, accountType: AccountTypeViewItem) -> CGFloat {
        let contentWidth = CardCell.contentWidth(containerWidth: containerWidth) - RestoreAccountCell.horizontalPadding * 2
        let accountViewHeight = AccountDoubleLineCellView.height(containerWidth: contentWidth, title: RestoreAccountCell.titleText(accountType: accountType), subtitle: accountType.coinCodes)

        let contentHeight = accountViewHeight + RestoreAccountCell.topPadding + RestoreAccountCell.bottomPadding
        return CardCell.height(contentHeight: contentHeight)
    }

}
