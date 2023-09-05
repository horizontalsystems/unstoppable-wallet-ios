import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class PlaceholderCell: BaseThemeCell {
    private let placeholderView = PlaceholderView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var icon: UIImage? {
        get { placeholderView.image }
        set { placeholderView.image = newValue }
    }

    var text: String? {
        get { placeholderView.text }
        set { placeholderView.text = newValue }
    }

    @discardableResult func addPrimaryButton(style: PrimaryButton.Style, title: String, target: Any, action: Selector) -> UIButton {
        placeholderView.addPrimaryButton(style: style, title: title, target: target, action: action)
    }

    func removeAllButtons() {
        placeholderView.removeAllButtons()
    }

}
