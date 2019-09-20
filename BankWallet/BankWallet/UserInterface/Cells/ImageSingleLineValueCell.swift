import UIKit
import SnapKit

class ImageSingleLineValueCell: AppCell {
    private let leftView = LeftImageCellView()
    private let middleView = SingleLineCellView()
    private let rightView = RightValueCellView()
    private let disclosureView = DisclosureCellView()

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
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(middleView.snp.trailing)
        }

        contentView.addSubview(disclosureView)
        disclosureView.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.leading.equalTo(rightView.snp.trailing)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(image: UIImage?, title: String?, value: String?, last: Bool = false) {
        super.bind(last: last)

        leftView.bind(image: image)
        middleView.bind(text: title)
        rightView.bind(text: value)
    }

}
