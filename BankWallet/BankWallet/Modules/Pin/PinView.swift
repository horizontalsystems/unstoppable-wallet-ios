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
            maker.center.equalToSuperview()
        }

        descriptionLabel.font = PinTheme.infoFontRegular
        descriptionLabel.textColor = PinTheme.infoColor
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.bottom.equalTo(self.pinDotsView.snp.top).offset(-PinTheme.infoVerticalMargin)
            maker.leading.equalToSuperview().offset(PinTheme.infoHorizontalMargin)
            maker.trailing.equalToSuperview().offset(-PinTheme.infoHorizontalMargin)
        }

        errorLabel.font = PinTheme.infoFontRegular
        errorLabel.textColor = PinTheme.errorColor
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
        descriptionLabel.text = page.description?.localized
        errorLabel.text = page.error?.localized

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
