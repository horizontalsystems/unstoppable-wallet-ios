import UIKit
import ThemeKit
import ComponentKit

class FaqCell: BaseSelectableThemeCell {
    private static let padding: CGFloat = .margin16
    private static let font: UIFont = .subhead1

    private let label = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(FaqCell.padding)
        }

        label.numberOfLines = 0
        label.font = FaqCell.font
        label.textColor = .themeLeah
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

}

extension FaqCell {

    static func height(containerWidth: CGFloat, text: String, backgroundStyle: BackgroundStyle) -> CGFloat {
        let textWidth = containerWidth - 2 * padding - Self.margin(backgroundStyle: backgroundStyle).width
        let textHeight = text.height(forContainerWidth: textWidth, font: font)

        return padding + textHeight + padding
    }

}
