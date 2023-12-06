import ComponentKit
import UIKit

class BorderedEmptyCell: EmptyCell {
    let topBorder = UIView()
    let bottomBorder = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(topBorder)
        topBorder.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        topBorder.backgroundColor = .themeSteel20
        topBorder.isHidden = true

        contentView.addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        bottomBorder.backgroundColor = .themeSteel20
        bottomBorder.isHidden = true
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
