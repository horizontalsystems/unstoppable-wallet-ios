import UIKit
import SnapKit

class PinView: UIView {

    private var pinDotsView = PinDotsView()
    private var descriptionLabel = UILabel()
    private var errorLabel = UILabel()

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
            maker.bottom.equalTo(self.pinDotsView.snp.top).offset(-PinTheme.infoBottomMargin)
            maker.centerX.equalToSuperview()
            maker.leading.equalToSuperview().offset(PinTheme.infoMargin)
            maker.trailing.equalToSuperview().offset(-PinTheme.infoMargin)
        }

        errorLabel.font = PinTheme.infoFontRegular
        errorLabel.textColor = PinTheme.infoColor
        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        addSubview(errorLabel)
        errorLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.pinDotsView.snp.bottom).offset(PinTheme.infoBottomMargin)
            maker.centerX.equalToSuperview()
            maker.leading.equalToSuperview().offset(PinTheme.infoMargin)
            maker.trailing.equalToSuperview().offset(-PinTheme.infoMargin)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return pinDotsView.becomeFirstResponder()
    }

    func bind(page: PinPage, onPinChange: ((String) -> ())? = nil) {
        descriptionLabel.text = page.description?.localized
        errorLabel.text = page.error?.localized

        pinDotsView.clean()
        pinDotsView.onPinEnter = onPinChange
        if page.showKeyboard, !pinDotsView.isFirstResponder {
            pinDotsView.becomeFirstResponder()
        }
    }

    func shakeAndClear() {
        pinDotsView.shakeView {
            self.pinDotsView.clean()
        }
    }

}
