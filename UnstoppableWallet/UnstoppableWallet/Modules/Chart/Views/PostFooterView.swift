import UIKit
import SnapKit

class PostFooterView: UIView {
    private static let titleFont = UIFont.caption
    private static let titleColor = UIColor.themeGray

    private let titleLabel = UILabel()

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin8x)
        }

        titleLabel.font = PostFooterView.titleFont
        titleLabel.textColor = PostFooterView.titleColor
        titleLabel.textAlignment = .center
        titleLabel.text = "@CryptoCompare.com"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension PostFooterView {

    static var height: CGFloat {
        PostFooterView.titleFont.lineHeight + CGFloat.margin3x + CGFloat.margin8x
    }

}
