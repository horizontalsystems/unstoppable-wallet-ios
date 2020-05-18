import UIKit

class TransactionInfoTitleView: UIView {
    private let label = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        label.font = .subhead2
        label.textColor = .themeGray
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String) {
        label.text = text
    }

}
