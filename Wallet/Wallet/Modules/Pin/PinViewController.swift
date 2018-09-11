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

        for _ in 0..<4 {
            dotsViews.append(dotView)
        }
        dotsHolder = UIStackView(arrangedSubviews: dotsViews)
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
        dotsHolder.layoutSubviews()
        delegate.viewDidLoad()

        textField.keyboardType = .numberPad
        textField.keyboardAppearance = AppTheme.keyboardAppearance
        wrapperView.addSubview(textField)
        textField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalTo(self.view.snp.bottom)
            maker.size.equalTo(CGSize(width: 0, height: 0))
        }
        textField.becomeFirstResponder()
        textField.addTarget(self, action: #selector(onPinChange), for: .editingChanged)
    }

    @objc func onPinChange() {
        print("pin: \(textField.text)")
    }

    override func updateUI(keyboardHeight: CGFloat, duration: TimeInterval, options: UIViewAnimationOptions, completion: (() -> ())?) {
        wrapperView.snp.updateConstraints { maker in
            maker.bottom.equalToSuperview().offset(-keyboardHeight)
        }
    }
}

extension PinViewController: IPinView {

}
