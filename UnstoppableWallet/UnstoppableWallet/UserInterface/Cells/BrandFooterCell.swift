import UIKit
import SnapKit
import ThemeKit

class BrandFooterCell: UITableViewCell {
    static let brandText = "© Horizontal Systems 2022"

    private let brandFooterView = BrandFooterView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(brandFooterView)
        brandFooterView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var title: String? {
        get { brandFooterView.title }
        set { brandFooterView.title = newValue }
    }

}

extension BrandFooterCell {

    static func height(containerWidth: CGFloat, title: String) -> CGFloat {
        BrandFooterView.height(containerWidth: containerWidth, title: title)
    }

}
