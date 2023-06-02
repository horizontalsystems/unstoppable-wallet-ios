import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class HeaderAmountView: UIView {
    static let height: CGFloat = 131

    private let amountButton = TextButtonComponent()
    private let convertedAmountButton = TextButtonComponent()

    init() {
        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(Self.height)
        }

        addSubview(amountButton)
        amountButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(CGFloat.margin32)
            make.centerX.equalToSuperview()
        }

        amountButton.font = .title2R

        addSubview(convertedAmountButton)
        convertedAmountButton.snp.makeConstraints { make in
            make.top.equalTo(amountButton.snp.bottom).offset(CGFloat.margin6)
            make.centerX.equalToSuperview()
        }

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
