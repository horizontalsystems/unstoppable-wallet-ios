import UIKit
import GrouviExtensions

class PinDotsView: UIView {

    private var dotsHolder = UIStackView()
    private var dotsViews = [TintImageView]()

    private var textField = UITextField()

    private var pinLength: Int

    var onPinEnter: ((String) -> ())?

    init(pinLength: Int? = nil, onEnterPin: ((String) -> ())? = nil) {

        self.pinLength = pinLength ?? 6
        super.init(frame: .zero)

        dotsHolder.backgroundColor = .yellow
        dotsHolder.axis = .horizontal
        dotsHolder.distribution = .equalSpacing
        dotsHolder.alignment = .center
        dotsHolder.spacing = PinTheme.dotsMargin
        addSubview(dotsHolder)
        dotsHolder.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        textField.delegate = self
        textField.keyboardType = .numberPad
        textField.keyboardAppearance = AppTheme.keyboardAppearance
        addSubview(textField)
        textField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalTo(self.snp.bottom)
            maker.size.equalTo(CGSize(width: 0, height: 0))
        }
        textField.addTarget(self, action: #selector(afterPinEnter), for: .editingChanged)

        for _ in 0..<self.pinLength {
            let dotView = self.dotView
            dotsViews.append(dotView)
            dotsHolder.addArrangedSubview(dotView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var dotView: TintImageView {
        return TintImageView(image: UIImage(named: "Pin Dot"), selectedImage: UIImage(named: "Pin Dot Filled"))
    }

    @objc private func afterPinEnter() {
        highlightPinDot()
        if let pin = textField.text, pin.count == pinLength {
            onPinEnter?(pin)
        }
    }

    func clean() {
        self.textField.text = nil
        highlightPinDot()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }

    func highlightPinDot() {
        let index = (textField.text?.count ?? 0) - 1
        for (dotViewIndex, dotView) in dotsViews.enumerated() {
            dotView.isHighlighted = dotViewIndex <= index
        }
    }

}

extension PinDotsView: UITextFieldDelegate {

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldLength = textField.text?.count ?? 0
        let replacementLength = string.count
        let rangeLength = range.length

        let newLength = oldLength - rangeLength + replacementLength;

        let shouldChange = newLength <= pinLength
        if !shouldChange {
            self.shakeView()
        }
        return shouldChange
    }

}

