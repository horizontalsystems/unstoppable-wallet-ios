import UIKit
import GrouviExtensions
import SnapKit

class PinViewController: KeyboardObservingViewController {

    let delegate: IPinViewDelegate

    let wrapperView = UIView()

    let infoLabel = UILabel()

    var dotsHolder = UIStackView()
    var dotsViews = [TintImageView]()

    var textField = UITextField()
    var pinLength = 0

    var dotView: TintImageView {
        return TintImageView(image: UIImage(named: "Pin Dot"), selectedImage: UIImage(named: "Pin Dot Filled"))
    }

    init(viewDelegate: IPinViewDelegate) {
        self.delegate = viewDelegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.controllerBackground

        wrapperView.backgroundColor = AppTheme.controllerBackground
        view.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        infoLabel.textColor = PinTheme.infoColor
        infoLabel.lineBreakMode = .byWordWrapping
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        wrapperView.addSubview(infoLabel)

        dotsHolder.backgroundColor = .yellow
        dotsHolder.axis = .horizontal
        dotsHolder.distribution = .equalSpacing
        dotsHolder.alignment = .center
        dotsHolder.spacing = PinTheme.dotsMargin
        wrapperView.addSubview(dotsHolder)
        dotsHolder.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        textField.delegate = self
        textField.keyboardType = .numberPad
        textField.keyboardAppearance = AppTheme.keyboardAppearance
        wrapperView.addSubview(textField)
        textField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalTo(self.view.snp.bottom)
            maker.size.equalTo(CGSize(width: 0, height: 0))
        }
        textField.addTarget(self, action: #selector(onPinChange), for: .editingChanged)

        delegate.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }

    @objc func onPinChange() {
        delegate.onPinChange(pin: textField.text)
    }

    override func updateUI(keyboardHeight: CGFloat, duration: TimeInterval, options: UIViewAnimationOptions, completion: (() -> ())?) {
        wrapperView.snp.updateConstraints { maker in
            maker.bottom.equalToSuperview().offset(-keyboardHeight)
        }
    }

}

extension PinViewController: UITextFieldDelegate {

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldLength = textField.text?.count ?? 0
        let replacementLength = string.count
        let rangeLength = range.length

        let newLength = oldLength - rangeLength + replacementLength;

        let shouldChange = newLength <= pinLength
        if !shouldChange {
            onWrongPin(clean: false)
        }
        return shouldChange
    }

}

extension PinViewController: IPinView {

    func highlightPinDot(at index: Int) {
        for (dotViewIndex, dotView) in dotsViews.enumerated() {
            dotView.isHighlighted = dotViewIndex <= index
        }
    }

    func bind(pinLength: Int, title: String?, infoText: String, infoFont: UIFont, infoAttachToTop: Bool) {
        self.pinLength = pinLength
        for _ in 0..<pinLength {
            let dotView = self.dotView
            dotsViews.append(dotView)
            dotsHolder.addArrangedSubview(dotView)
        }

        self.title = title
        infoLabel.text = infoText
        infoLabel.font = infoFont
        infoLabel.snp.remakeConstraints { maker in
            if infoAttachToTop {
                maker.top.equalToSuperview().offset(PinTheme.infoTopMargin)
            } else {
                maker.bottom.equalTo(self.dotsHolder.snp.top).offset(-PinTheme.infoBottomMargin)
            }

            maker.centerX.equalToSuperview()
            maker.leading.equalToSuperview().offset(PinTheme.infoMargin)
            maker.trailing.equalToSuperview().offset(-PinTheme.infoMargin)
        }
    }

    func onWrongPin(clean: Bool) {
        dotsHolder.shakeView()
        if clean {
            textField.text = nil
            delegate.onPinChange(pin: nil)
        }
    }

}
