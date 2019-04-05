import UIKit
import SnapKit

class PinView: UIView {

    let pinDotsView = PinDotsView()
    private let descriptionLabel = UILabel()
    private let errorLabel = UILabel()
    private let cancelButtonView = UIView()
    private let cancelButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(pinDotsView)
        pinDotsView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().multipliedBy(0.7)
        }

        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.bottom.equalTo(self.pinDotsView.snp.top).offset(-PinTheme.infoVerticalMargin)
            maker.leading.equalToSuperview().offset(PinTheme.infoHorizontalMargin)
            maker.trailing.equalToSuperview().offset(-PinTheme.infoHorizontalMargin)
        }

        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        addSubview(errorLabel)
        errorLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.pinDotsView.snp.bottom).offset(PinTheme.infoVerticalMargin)
            maker.leading.equalToSuperview().offset(PinTheme.infoHorizontalMargin)
            maker.trailing.equalToSuperview().offset(-PinTheme.infoHorizontalMargin)
        }

        addSubview(cancelButtonView)
        cancelButtonView.snp.makeConstraints { maker in
            maker.top.equalTo(self.pinDotsView)
            maker.leading.bottom.trailing.equalToSuperview()
        }

        cancelButton.setTitle("alert.cancel".localized, for: .normal)
        cancelButton.setTitleColor(PinTheme.cancelColor, for: .normal)
        cancelButton.setTitleColor(PinTheme.cancelSelectedColor, for: .highlighted)
        cancelButton.isHidden = true
        cancelButtonView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(page: PinPage, onPinChange: ((String) -> ())? = nil) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2.2
        style.alignment = .center
        let descriptionAttributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.foregroundColor: PinTheme.infoColor,
            NSAttributedStringKey.font: PinTheme.infoFontRegular,
            NSAttributedStringKey.paragraphStyle: style,
            NSAttributedStringKey.kern: -0.1
        ]
        let description = NSMutableAttributedString(string: page.description?.localized ?? "", attributes: descriptionAttributes)
        descriptionLabel.attributedText = description

        let errorAttributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.foregroundColor: PinTheme.errorColor,
            NSAttributedStringKey.font: PinTheme.infoFontRegular,
            NSAttributedStringKey.paragraphStyle: style,
            NSAttributedStringKey.kern: -0.1
        ]
        let error = NSMutableAttributedString(string: page.error?.localized ?? "", attributes: errorAttributes)
        errorLabel.attributedText = error

        pinDotsView.clean()
        pinDotsView.onPinEnter = onPinChange
    }

    func shakeAndClear() {
        pinDotsView.shakeView {
            self.pinDotsView.clean()
        }
    }

    func showCancelButton(target: Any?, action: Selector) {
        cancelButton.isHidden = false
        cancelButton.addTarget(target, action: action, for: .touchUpInside)
    }

}
