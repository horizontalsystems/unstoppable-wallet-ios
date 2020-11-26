import UIKit
import SnapKit
import ThemeKit

class DoubleButtonCell: UITableViewCell {
    private let verticalPadding: CGFloat = .margin24

    private let leftButton = ThemeButton()
    private let rightButton = ThemeButton()

    var onTapLeft: (() -> ())?
    var onTapRight: (() -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(leftButton)
        leftButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalToSuperview().inset(verticalPadding)
        }

        leftButton.apply(style: .secondaryDefault)
        leftButton.addTarget(self, action: #selector(onTapLeftButton), for: .touchUpInside)

        contentView.addSubview(rightButton)
        rightButton.snp.makeConstraints { maker in
            maker.leading.equalTo(leftButton.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalTo(leftButton)
            maker.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.width.equalTo(leftButton)
        }

        rightButton.apply(style: .secondaryDefault)
        rightButton.addTarget(self, action: #selector(onTapRightButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc private func onTapLeftButton() {
        onTapLeft?()
    }

    @objc private func onTapRightButton() {
        onTapRight?()
    }

    var leftTitle: String? {
        get { leftButton.title(for: .normal) }
        set { leftButton.setTitle(newValue, for: .normal) }
    }

    var rightTitle: String? {
        get { rightButton.title(for: .normal) }
        set { rightButton.setTitle(newValue, for: .normal) }
    }

    var cellHeight: CGFloat {
        ThemeButton.height(style: .secondaryDefault) + 2 * verticalPadding
    }

}
