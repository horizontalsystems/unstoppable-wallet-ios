import ComponentKit
import ThemeKit
import UIKit

class CheckboxCell: BaseSelectableThemeCell {
    private let checkBoxView = CheckboxView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        wrapperView.addSubview(checkBoxView)
        checkBoxView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?, checked: Bool, backgroundStyle: BackgroundStyle, isFirst: Bool = false, isLast: Bool = false) {
        set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
        checkBoxView.text = text

        checkBoxView.checked = checked
    }
}

extension CheckboxCell {
    static func height(containerWidth: CGFloat, text: String, backgroundStyle: BackgroundStyle) -> CGFloat {
        CheckboxView.height(containerWidth: containerWidth, text: text, insets: margin(backgroundStyle: backgroundStyle))
    }
}
