import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class HeaderAmountView: UIView {
    static let height: CGFloat = 131
    private let stackView = UIStackView()
    private let amountButton = TextButtonComponent()
    private let convertedAmountButton = TextButtonComponent()

    init() {
        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(HeaderAmountView.height)
        }

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = .margin6

        stackView.addArrangedSubview(amountButton)
        amountButton.font = .title2R

        stackView.addArrangedSubview(convertedAmountButton)

        convertedAmountButton.font = .body
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var onTapAmount: (() -> ())? {
        get { amountButton.onTap }
        set { amountButton.onTap = newValue }
    }

    var onTapConvertedAmount: (() -> ())? {
        get { convertedAmountButton.onTap }
        set { convertedAmountButton.onTap = newValue }
    }

    func set(amountText: String?, expired: Bool) {
        amountButton.text = amountText
        amountButton.textColor = expired ? .themeGray50 : .themeLeah
    }

    func set(convertedAmountText: String?, expired: Bool) {
        convertedAmountButton.text = convertedAmountText
        convertedAmountButton.textColor = expired ? .themeGray50 : .themeGray
    }

}
