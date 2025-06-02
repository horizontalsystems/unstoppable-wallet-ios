import SnapKit
import ThemeKit
import UIKit

open class BottomDescriptionHeaderFooterView: UITableViewHeaderFooterView {
    private let descriptionView = BottomDescriptionView()

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().priority(.high)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func bind(text: String, textColor: UIColor = .themeGray, topMargin: CGFloat = .margin12, bottomMargin: CGFloat = .margin32) {
        descriptionView.bind(text: text, textColor: textColor, topMargin: topMargin, bottomMargin: bottomMargin)
    }
}

public extension BottomDescriptionHeaderFooterView {
    static func height(containerWidth: CGFloat, text: String, topMargin: CGFloat = .margin12, bottomMargin: CGFloat = .margin32) -> CGFloat {
        BottomDescriptionView.height(containerWidth: containerWidth, text: text, topMargin: topMargin, bottomMargin: bottomMargin)
    }
}
