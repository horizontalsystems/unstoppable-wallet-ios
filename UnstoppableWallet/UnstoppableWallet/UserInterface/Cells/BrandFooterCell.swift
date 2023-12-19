import SnapKit
import ThemeKit
import UIKit

class BrandFooterCell: UITableViewCell {
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

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
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
