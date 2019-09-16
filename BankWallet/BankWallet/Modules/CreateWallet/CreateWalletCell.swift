import UIKit
import SnapKit

class CreateWalletCell: AppCell {
    private let leftView = DoubleLineImageCellView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: CreateWalletViewItem, last: Bool = false) {
        super.bind(last: last)

        leftView.bind(
                image: UIImage(named: "\(viewItem.code.lowercased())")?.tinted(with: AppTheme.coinIconColor),
                title: viewItem.code,
                subtitle: viewItem.title
        )
    }

}
