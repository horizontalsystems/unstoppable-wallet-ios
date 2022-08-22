import UIKit
import ThemeKit
import SnapKit

class InputStackView: UIView {
    private let stackView = UIStackView()
    private let formTextView: IFormTextView
    private var leftViews = [(ISizeAwareView, CGFloat)]()
    private var rightViews = [ISizeAwareView]()

    init(singleLine: Bool = false) {
        if singleLine {
            formTextView = SingleLineFormTextView()
        } else {
            formTextView = FormTextView()
        }
        super.init(frame: .zero)

        formTextView.textViewInset = UIEdgeInsets(top: .margin12, left: 0, bottom: .margin12, right: 0)

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stackView.spacing = .margin8
        stackView.alignment = .fill
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
        stackView.isLayoutMarginsRelativeArrangement = true

        stackView.addArrangedSubview(formTextView)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        formTextView.becomeFirstResponder()
    }

    var editable: Bool {
        get { stackView.isUserInteractionEnabled }
        set { stackView.isUserInteractionEnabled = newValue }
    }

}

extension InputStackView {

    var placeholder: String? {
        get { formTextView.placeholder }
        set { formTextView.placeholder = newValue }
    }

    var text: String? {
        get { formTextView.text }
        set { formTextView.text = newValue }
    }

    var textColor: UIColor? {
        get { formTextView.textColor }
        set { formTextView.textColor = newValue }
    }

    var font: UIFont? {
        get { formTextView.font }
        set { formTextView.font = newValue }
    }

    var isEditable: Bool {
        get { formTextView.isEditable }
        set { formTextView.isEditable = newValue }
    }

//    var maximumNumberOfLines: Int {
//        get { formTextView.maximumNumberOfLines }
//        set { formTextView.maximumNumberOfLines = newValue }
//    }

    var keyboardType: UIKeyboardType {
        get { formTextView.keyboardType }
        set { formTextView.keyboardType = newValue }
    }

    var autocapitalizationType: UITextAutocapitalizationType {
        get { formTextView.autocapitalizationType }
        set { formTextView.autocapitalizationType = newValue }
    }

    var autocorrectionType: UITextAutocorrectionType {
        get { formTextView.autocorrectionType }
        set { formTextView.autocorrectionType = newValue }
    }

    var onChangeText: ((String?) -> ())? {
        get { formTextView.onChangeText }
        set { formTextView.onChangeText = newValue }
    }

    var onChangeEditing: ((Bool) -> ())? {
        get { formTextView.onChangeEditing }
        set { formTextView.onChangeEditing = newValue }
    }

    var isValidText: ((String) -> Bool)? {
        get { formTextView.isValidText }
        set { formTextView.isValidText = newValue }
    }

    func prependSubview(_ view: ISizeAwareView, customSpacing: CGFloat? = nil) {
        let spacing = customSpacing ?? stackView.spacing

        leftViews.insert((view, spacing), at: 0)
        stackView.insertArrangedSubview(view, at: 0)

        if let customSpacing = customSpacing {
            stackView.setCustomSpacing(customSpacing, after: view)
        }
    }

    func appendSubview(_ view: ISizeAwareView) {
        rightViews.append(view)
        stackView.addArrangedSubview(view)
    }

}

extension InputStackView: IHeightControlView {

    var onChangeHeight: (() -> ())? {
        get { formTextView.onChangeHeight }
        set { formTextView.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        var textViewWidth = containerWidth - stackView.layoutMargins.width
        let visibleLeftViews = leftViews.filter { !$0.0.isHidden }
        let visibleRightViews = rightViews.filter { !$0.isHidden }

        for (view, spacing) in visibleLeftViews {
            textViewWidth -= view.width(containerWidth: .greatestFiniteMagnitude) + spacing
        }


        for view in visibleRightViews {
            textViewWidth -= view.width(containerWidth: .greatestFiniteMagnitude) + stackView.spacing
        }

        return formTextView.height(containerWidth: textViewWidth)
    }

}

protocol ISizeAwareView: UIView {
    func width(containerWidth: CGFloat) -> CGFloat
}
