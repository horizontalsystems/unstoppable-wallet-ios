import UIKit
import UIExtensions

class PinDotsView: UIView {

    private var dotsHolder = UIStackView()
    private var dotsViews = [TintImageView]()

    private var pinLength: Int
    private var enteredPin = ""

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

        for _ in 0..<self.pinLength {
            let dotView = self.dotView
            dotsViews.append(dotView)
            dotsHolder.addArrangedSubview(dotView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var dotView: TintImageView {
        return TintImageView(image: UIImage(named: "Pin Dot"), selectedImage: UIImage(named: "Pin Dot Filled"))
    }

    func append(digit: String) {
        if enteredPin.count < pinLength {
            enteredPin.append(digit)
            afterPinEnter()
        }
    }

    func removeLastDigit() {
        if enteredPin.count > 0 {
            enteredPin.removeLast()
            afterPinEnter()
        }
    }

    func clean() {
        self.enteredPin = ""
        highlightPinDot()
    }

    private func afterPinEnter() {
        highlightPinDot()

        if enteredPin.count == pinLength {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.onPinEnter?(self.enteredPin)
            }
        }
    }

    private func highlightPinDot() {
        let index = enteredPin.count - 1
        for (dotViewIndex, dotView) in dotsViews.enumerated() {
            dotView.isHighlighted = dotViewIndex <= index
        }
    }

}
