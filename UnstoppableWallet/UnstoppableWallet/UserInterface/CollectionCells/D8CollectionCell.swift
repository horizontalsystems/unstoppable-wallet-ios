import UIKit
import ThemeKit
import ComponentKit

class D8CollectionCell: BaseThemeCollectionCell {
    private let leftView = LeftDView()
    private let rightView = Right8View()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layout(leftView: leftView, rightView: rightView)

        rightView.textColor = .themeLeah
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var title: String? {
        get { leftView.text }
        set { leftView.text = newValue }
    }

    public var value: String? {
        get { rightView.text }
        set { rightView.text = newValue }
    }

}
