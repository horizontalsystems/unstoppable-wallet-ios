import UIKit
import ThemeKit

class BlockchainSettingsListCell: ThemeCell {

    let doubleLineView = DoubleLineCellView(frame: .zero)

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(doubleLineView)
        doubleLineView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(item: BlockchainSettingsListViewItem, last: Bool) {
        super.bind(showDisclosure: true, last: last, active: item.enabled)

        doubleLineView.bind(title: item.title, subtitle: item.subtitle, active: item.enabled)
        selectionStyle = item.enabled ? .default : .none
    }

}
