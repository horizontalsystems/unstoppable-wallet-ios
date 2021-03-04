import UIKit
import SnapKit
import ThemeKit

class SimpleSheetTitleView: UIView {
    static let height: CGFloat = 40

    private let textLabel = UILabel()
    private let separatorView = UIView()

    var onTapClose: (() -> ())?

    init() {
        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(SimpleSheetTitleView.height)
        }

        addSubview(textLabel)
        textLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        textLabel.font = .subhead1
        textLabel.textColor = .themeGray
        textLabel.textAlignment = .center

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapClose() {
        onTapClose?()
    }

    var text: String? {
        get { textLabel.text }
        set { textLabel.text = newValue }
    }

    var textColor: UIColor {
        get { textLabel.textColor }
        set { textLabel.textColor = newValue }
    }

}
