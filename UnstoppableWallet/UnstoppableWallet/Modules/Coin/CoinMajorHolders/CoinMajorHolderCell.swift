import ComponentKit
import ThemeKit
import SnapKit
import UIKit

class CoinMajorHolderCell: BaseThemeCell {
    private let leftView = LeftBBView()
    private let rightView = Right10View()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(Self.leftInset)
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(120)
        }

        wrapperView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.leading.equalTo(leftView.snp.trailing)
            maker.trailing.equalToSuperview().inset(Self.rightInset)
            maker.top.bottom.equalToSuperview()
        }

        leftView.textColor = .themeJacob
        rightView.set(iconButtonImage: UIImage(named: "globe_20"))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var numberText: String? {
        get { leftView.numberText }
        set { leftView.numberText = newValue }
    }

    var title: String? {
        get { leftView.text }
        set { leftView.text = newValue }
    }

    func set(address: String) {
        rightView.viewItem = .init(type: .raw, value: { address })
    }

    var onTapIcon: (() -> ())? {
        get { rightView.onTapIconButton }
        set { rightView.onTapIconButton = newValue }
    }

}
