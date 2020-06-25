import UIKit
import ThemeKit
import SnapKit

class CaptionValueView: UIView {
    private let captionLabel = UILabel()
    private let valueButton = UIButton()

    private var _onTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(captionLabel)
        captionLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview()
        }

        captionLabel.font = .subhead2
        captionLabel.textColor = .themeGray

        addSubview(valueButton)
        valueButton.snp.makeConstraints { maker in
            maker.leading.equalTo(captionLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        valueButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: .margin3x, right: 0)//left, right insets are conflicting with hugging priority
        valueButton.setContentHuggingPriority(.required, for: .horizontal)
        valueButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        _onTap?()
    }

    func set(caption: String?) {
        captionLabel.text = caption
    }

    func set(value: String?, accent: Bool = true, font: UIFont = .subhead2, link: Bool = false, onTap: (() -> ())? = nil) {
        _onTap = onTap

        valueButton.isUserInteractionEnabled = link

        if link, let value = value {
            let color: UIColor = accent ? .themeJacob : .themeGray50
            let linkString: NSAttributedString = NSAttributedString(string: value, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue, .font: font, .foregroundColor: color])
            valueButton.setAttributedTitle(linkString, for: .normal)

            let selectedColor: UIColor = accent ? .themeYellow50 : .themeGray50
            let selectedLinkString: NSAttributedString = NSAttributedString(string: value, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue, .font: font, .foregroundColor: selectedColor])
            valueButton.setAttributedTitle(selectedLinkString, for: .highlighted)
        } else {
            let color: UIColor = accent ? .themeLeah : .themeGray50
            valueButton.titleLabel?.font = font
            valueButton.setTitle(value, for: .normal)
            valueButton.setTitleColor(color, for: .normal)
        }
    }

}
