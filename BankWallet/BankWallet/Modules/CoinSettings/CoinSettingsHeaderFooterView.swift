import UIKit
import SnapKit

class CoinSettingsHeaderFooterView: UITableViewHeaderFooterView {
    private static let sideMargin: CGFloat = .margin6x
    private static let topMargin: CGFloat = .margin2x
    private static let bottomMargin: CGFloat = .margin12x
    private static let buttonHeight: CGFloat = ceil(font.lineHeight)
    private static let font: UIFont = .subhead2

    private let label = UILabel()
    private let button = UIButton()

    private var onTap: (() -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        label.numberOfLines = 0
        label.font = CoinSettingsHeaderFooterView.font
        label.textColor = .themeGray

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CoinSettingsHeaderFooterView.sideMargin)
            maker.top.equalToSuperview().offset(CoinSettingsHeaderFooterView.topMargin)
        }

        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CoinSettingsHeaderFooterView.sideMargin)
            maker.top.equalTo(label.snp.bottom)
            maker.height.equalTo(CoinSettingsHeaderFooterView.buttonHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onTapButton() {
        onTap?()
    }

    func bind(text: String, url: String, onTap: (() -> ())?) {
        label.text = text
        button.setAttributedTitle(urlString(url: url, color: .themeOz), for: .normal)
        button.setAttributedTitle(urlString(url: url, color: .themeGray50), for: .highlighted)

        self.onTap = onTap
    }

    private func urlString(url: String, color: UIColor) -> NSAttributedString {
        NSAttributedString(
                string: url,
                attributes: [
                    .font: CoinSettingsHeaderFooterView.font,
                    .foregroundColor: color,
                    .underlineStyle: 1,
                    .underlineColor: color
                ]
        )
    }

}

extension CoinSettingsHeaderFooterView {

    static func height(containerWidth: CGFloat, text: String, url: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * CoinSettingsHeaderFooterView.sideMargin, font: CoinSettingsHeaderFooterView.font)
        return textHeight + CoinSettingsHeaderFooterView.buttonHeight + CoinSettingsHeaderFooterView.topMargin + CoinSettingsHeaderFooterView.bottomMargin
    }

}
