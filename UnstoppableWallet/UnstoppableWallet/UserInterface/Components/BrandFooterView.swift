import UIKit
import ThemeKit
import SnapKit

class BrandFooterView: UIView {
    private static let topPadding: CGFloat = .margin12
    private static let bottomPadding: CGFloat = .margin32
    private static let horizontalPadding: CGFloat = .margin24
    private static let labelFont: UIFont = .caption

    private let separatorView = UIView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalPadding)
            maker.top.equalTo(separatorView.snp.top).offset(Self.topPadding)
            maker.bottom.equalToSuperview().inset(Self.bottomPadding)
        }

        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Self.labelFont
        label.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

}

extension BrandFooterView {

    static func height(containerWidth: CGFloat, title: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalPadding
        let textHeight = title.height(forContainerWidth: textWidth, font: labelFont)

        return topPadding + textHeight + bottomPadding
    }

}
