import UIKit
import SnapKit
import ThemeKit

class RestoreSelectPredefinedAccountTypeCell: CardCell {
    private static let topPadding: CGFloat = 10
    private static let bottomPadding: CGFloat = .margin3x
    private static let horizontalPadding: CGFloat = .margin3x

    private let accountView = AccountDoubleLineCellView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clippingView.addSubview(accountView)
        accountView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(RestoreSelectPredefinedAccountTypeCell.horizontalPadding)
            maker.top.equalToSuperview().offset(RestoreSelectPredefinedAccountTypeCell.topPadding)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: RestoreSelectPredefinedAccountTypeViewModel.ViewItem) {
        accountView.bind(title: RestoreSelectPredefinedAccountTypeCell.titleText(viewItem: viewItem), subtitle: viewItem.coinCodes)
    }

}

extension RestoreSelectPredefinedAccountTypeCell {

    static func titleText(viewItem: RestoreSelectPredefinedAccountTypeViewModel.ViewItem) -> String {
        "restore.item_title".localized(viewItem.title)
    }

    static func height(containerWidth: CGFloat, viewItem: RestoreSelectPredefinedAccountTypeViewModel.ViewItem) -> CGFloat {
        let contentWidth = CardCell.contentWidth(containerWidth: containerWidth) - RestoreSelectPredefinedAccountTypeCell.horizontalPadding * 2
        let accountViewHeight = AccountDoubleLineCellView.height(containerWidth: contentWidth, title: RestoreSelectPredefinedAccountTypeCell.titleText(viewItem: viewItem), subtitle: viewItem.coinCodes)

        let contentHeight = accountViewHeight + RestoreSelectPredefinedAccountTypeCell.topPadding + RestoreSelectPredefinedAccountTypeCell.bottomPadding
        return CardCell.height(contentHeight: contentHeight)
    }

}
