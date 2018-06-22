import UIKit
import SnapKit

@IBDesignable
class IndexedInputField: UIView, UITextFieldDelegate {

    var textField: UITextField
    var indexLabel: UILabel

    var clearWrapperView: UIView
    var clearTextButton: UIButton
    var clearTextImageView: UIImageView

    @IBInspectable var contentBackgroundColor: UIColor? {
        get {
            return backgroundColor
        }
        set {
            backgroundColor = newValue
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue != 0
        }
    }
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    var onReturn: (() ->())?

    override init(frame: CGRect) {
        indexLabel = UILabel()
        textField = UITextField()

        clearWrapperView = UIView()
        clearTextButton = UIButton()
        clearTextImageView = UIImageView(image: UIImage(named: "Cancel Input Icon"))
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        indexLabel = UILabel()
        textField = UITextField()

        clearWrapperView = UIView()
        clearTextButton = UIButton()
        clearTextImageView = UIImageView(image: UIImage(named: "Cancel Input Icon"))
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        clearTextButton.addTarget(self, action: #selector(onClearText), for: .touchUpInside)

        clearWrapperView.isHidden = true
        clearWrapperView.addSubview(clearTextImageView)
        clearWrapperView.addSubview(clearTextButton)
        clearTextButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        clearTextImageView.snp.makeConstraints { maker in
            maker.width.height.equalTo(14)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-14)
        }
        addSubview(clearWrapperView)
        clearWrapperView.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(48)
        }

        addSubview(indexLabel)
        indexLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(16)
            maker.centerY.equalToSuperview()
        }
        indexLabel.textColor = .cryptoSilver

        textField.addTarget(self, action: #selector(onTextChange), for: .editingChanged)
        textField.textColor = .white
        textField.delegate = self
        addSubview(textField)
        textField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(48)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalTo(self.clearWrapperView.snp.leading)
        }
    }

    @objc func onClearText() {
        textField.text = nil
        clearWrapperView.isHidden = textField.text?.isEmpty ?? true
    }

    @objc func onTextChange() {
        clearWrapperView.isHidden = textField.text?.isEmpty ?? true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        clearWrapperView.isHidden = textField.text?.isEmpty ?? true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        clearWrapperView.isHidden = true
    }


}
