import UIKit
import SnapKit

class CreateWalletCell: AppCell {
    private let leftView = DoubleLineImageCellView()
    private let rightView = SwitchCellView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.top.leading.bottom.equalToSuperview()
        }

        contentView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.leading.equalTo(leftView.snp.trailing)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: CreateWalletViewItem, last: Bool = false, onSwitch: @escaping (Bool) -> ()) {
        super.bind(last: last)

        leftView.bind(
                image: UIImage(named: "\(viewItem.code.lowercased())")?.tinted(with: AppTheme.coinIconColor),
                title: viewItem.code,
                subtitle: viewItem.title
        )

        rightView.bind(
                isOn: viewItem.selected,
                onSwitch: onSwitch
        )
    }

}
