import UIKit
import SnapKit
import ThemeKit

class SingleLineCell: ThemeCell {
    private let leftView = SingleLineCellView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?, last: Bool = false) {
        super.bind(last: last)

        leftView.bind(text: text)
    }

}
