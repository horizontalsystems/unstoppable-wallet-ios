import UIKit
import ThemeKit

class TransactionInfoFromToCell: ThemeCell {
    private let titleView = TransactionInfoTitleView()
    private let button = ThemeButton()

    private var onTap: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.equalTo(titleView.snp.trailing)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        button.apply(style: .secondaryDefault)
        button.addTarget(self, action: #selector(_onTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTap() {
        onTap?()
    }

    func bind(title: String, value: String, onTap: @escaping () -> ()) {
        super.bind(bottomSeparatorVisible: true)

        titleView.bind(text: title)
        button.setTitle(value, for: .normal)

        self.onTap = onTap
    }

}
