import UIKit
import SnapKit

class ImageDoubleLineCell: AppCell {
    private let leftView = LeftImageCellView()
    private let rightView = DoubleLineCellView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        contentView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.trailing.top.bottom.equalToSuperview()
            maker.leading.equalTo(leftView.snp.trailing)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(image: UIImage?, title: String?, subtitle: String?, last: Bool = false) {
        super.bind(last: last)

        leftView.bind(image: image)
        rightView.bind(title: title, subtitle: subtitle)
    }

}
