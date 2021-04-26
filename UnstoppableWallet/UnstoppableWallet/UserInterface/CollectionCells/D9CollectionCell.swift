import UIKit
import ThemeKit
import ComponentKit

class D9CollectionCell: BaseThemeCollectionCell {
    private let leftView = LeftDView()
    private let rightView = Right9View()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layout(leftView: leftView, rightView: rightView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var title: String? {
        get { leftView.text }
        set { leftView.text = newValue }
    }

    public var viewItem: CopyableSecondaryButton.ViewItem? {
        get { rightView.viewItem }
        set { rightView.viewItem = newValue }
    }

}
