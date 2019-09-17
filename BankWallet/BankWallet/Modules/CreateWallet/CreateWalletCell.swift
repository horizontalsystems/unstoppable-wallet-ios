import UIKit
import SnapKit

class CreateWalletCell: AppCell {
    private let leftView = LeftImageCellView()
    private let middleView = DoubleLineCellView()
    private let rightView = CheckmarkCellView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        contentView.addSubview(middleView)
        middleView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(leftView.snp.trailing)
        }

        contentView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.trailing.top.bottom.equalToSuperview()
            maker.leading.equalTo(middleView.snp.trailing)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: CreateWalletViewItem, last: Bool = false) {
        super.bind(last: last)

        leftView.bind(image: UIImage(named: "\(viewItem.code.lowercased())")?.tinted(with: AppTheme.coinIconColor))
        middleView.bind(title: viewItem.title, subtitle: viewItem.code)
        rightView.bind(visible: viewItem.selected)
    }

}
