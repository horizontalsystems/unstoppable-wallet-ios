import UIKit
import SnapKit

class HighlightedDescriptionView: HighlightedDescriptionBaseView {

    override public init() {
        super.init()

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(HighlightedDescriptionBaseView.sidePadding)
            maker.top.bottom.equalToSuperview().inset(HighlightedDescriptionBaseView.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = HighlightedDescriptionBaseView.font
        label.textColor = .themeLeah
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension HighlightedDescriptionView {

    public static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * sidePadding, font: font)
        return textHeight + 2 * verticalPadding
    }

}
