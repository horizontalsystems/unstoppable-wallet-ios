import SnapKit
import ThemeKit
import UIKit

class StackViewCell: UITableViewCell {
    private let stackView = UIStackView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.bottom.equalToSuperview()
        }

        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.spacing = .margin2x
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func add(view: UIView) {
        stackView.addArrangedSubview(view)
    }
}
