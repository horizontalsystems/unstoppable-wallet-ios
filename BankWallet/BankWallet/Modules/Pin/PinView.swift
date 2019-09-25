import UIKit
import SnapKit

class PinView: UIView {

    let pinDotsView = PinDotsView()
    private let topLabel = UILabel()
    private let cancelButtonView = UIView()
    private let cancelButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(pinDotsView)
        pinDotsView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().offset(CGFloat.margin6x)
        }

        topLabel.lineBreakMode = .byWordWrapping
        topLabel.numberOfLines = 0
        topLabel.textAlignment = .center
        addSubview(topLabel)
        topLabel.snp.makeConstraints { maker in
            maker.bottom.equalTo(self.pinDotsView.snp.top).offset(-PinTheme.infoVerticalMargin)
            maker.leading.equalToSuperview().offset(PinTheme.infoHorizontalMargin)
            maker.trailing.equalToSuperview().offset(-PinTheme.infoHorizontalMargin)
        }

        addSubview(cancelButtonView)
        cancelButtonView.snp.makeConstraints { maker in
            maker.top.equalTo(self.pinDotsView)
            maker.leading.bottom.trailing.equalToSuperview()
        }

        cancelButton.setTitle("button.cancel".localized, for: .normal)
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
        let error = page.error?.localized ?? ""
        let description = page.description?.localized ?? ""

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2.2
        style.alignment = .center
        let font: UIFont = page.isTitle ? .cryptoHeadline1 : .cryptoSubhead2
        let color: UIColor = page.isTitle ? .appOz : .cryptoGray
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: error.isEmpty ? color : .cryptoRed,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.kern: -0.1
        ]
        let attributedDescription = NSMutableAttributedString(string:  error.isEmpty ? description : error, attributes: attributes)
        topLabel.attributedText = attributedDescription

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
