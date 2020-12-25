import UIKit
import ThemeKit
import SnapKit

class InputStackView: UIView {
    private let stackView = UIStackView()
    private let formTextView = FormTextView()
    private var sideViews = [ISizeAwareView]()

    init() {
        super.init(frame: .zero)

        formTextView.textViewInset = UIEdgeInsets(top: .margin12, left: .margin4, bottom: .margin12, right: .margin4)

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stackView.spacing = .margin8
        stackView.alignment = .fill
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: .margin8, bottom: 0, right: .margin8)
        stackView.isLayoutMarginsRelativeArrangement = true

        stackView.addArrangedSubview(formTextView)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    var isEditable: Bool {
        get { formTextView.isUserInteractionEnabled }
        set { formTextView.isUserInteractionEnabled = newValue }
    }

    var maximumNumberOfLines: Int {
        get { formTextView.maximumNumberOfLines }
        set { formTextView.maximumNumberOfLines = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { formTextView.keyboardType }
        set { formTextView.keyboardType = newValue }
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

    func prependSubview(_ view: ISizeAwareView) {
        sideViews.insert(view, at: 0)
        stackView.insertArrangedSubview(view, at: 0)
    }

    func appendSubview(_ view: ISizeAwareView) {
        sideViews.append(view)
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
        let visibleSideViews = sideViews.filter { !$0.isHidden }

        for sideView in visibleSideViews {
            textViewWidth -= sideView.size(containerWidth: .greatestFiniteMagnitude).width + stackView.spacing
        }

        return formTextView.height(containerWidth: textViewWidth)
    }

}

protocol ISizeAwareView: UIView {
    func size(containerWidth: CGFloat) -> CGSize
}
