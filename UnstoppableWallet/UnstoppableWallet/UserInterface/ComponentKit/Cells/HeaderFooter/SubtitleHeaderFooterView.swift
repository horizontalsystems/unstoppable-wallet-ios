import SnapKit
import ThemeKit
import UIKit

open class SubtitleHeaderFooterView: UITableViewHeaderFooterView {
    private let label = UILabel()

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin32)
            maker.centerY.equalToSuperview()
        }

        label.font = .subhead1
        label.textColor = .themeGray
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func bind(text: String?, backgroundColor: UIColor = .clear) {
        label.text = text?.uppercased()
        backgroundView?.backgroundColor = backgroundColor
    }
}

public extension SubtitleHeaderFooterView {
    static let height: CGFloat = .margin32
}
