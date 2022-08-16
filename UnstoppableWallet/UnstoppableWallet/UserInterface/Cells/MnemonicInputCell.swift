import UIKit
import ThemeKit
import SnapKit

class MnemonicInputCell: UITableViewCell {
    private static let minimalTextViewHeight: CGFloat = 88

    private let horizontalMargin: CGFloat = .margin16
    private let textViewInset: CGFloat = .margin12
    private let textViewFont: UIFont = .body
    private let textViewTextColor: UIColor = .themeLeah

    private let borderView = UIView()
    private let textView = UITextView()

    var onChangeHeight: (() -> ())?
    var onChangeText: ((String, Int, String?) -> ())?
    var onChangeTextViewCaret: ((UITextView) -> ())?
    var onChangeEntering: (() -> ())?

    private(set) var entering = false {
        didSet {
            onChangeEntering?()
        }
    }

    private(set) var textForHeight: String = "" {
        didSet {
            onChangeHeight?()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(horizontalMargin)
            maker.top.bottom.equalToSuperview()
        }

        textView.keyboardAppearance = .themeDefault
        textView.backgroundColor = .themeLawrence
        textView.layer.cornerRadius = .cornerRadius8
        textView.layer.cornerCurve = .continuous
        textView.textColor = textViewTextColor
        textView.font = textViewFont
        textView.tintColor = .themeJacob
        textView.textContainerInset = UIEdgeInsets(top: textViewInset, left: textViewInset, bottom: textViewInset, right: textViewInset)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no

        textView.delegate = self

        contentView.addSubview(borderView)
        borderView.snp.makeConstraints { maker in
            maker.edges.equalTo(textView)
        }

        borderView.backgroundColor = .clear
        borderView.isUserInteractionEnabled = false
        borderView.layer.cornerRadius = .cornerRadius8
        borderView.layer.cornerCurve = .continuous
        borderView.layer.borderWidth = .heightOneDp
        borderView.layer.borderColor = UIColor.themeSteel20.cgColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

}

extension MnemonicInputCell: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        textForHeight = (textView.text as NSString).replacingCharacters(in: range, with: text)
        return true
    }

    public func textViewDidChange(_ textView: UITextView) {
        onChangeTextViewCaret?(textView)

        guard let selectedTextRange = textView.selectedTextRange else {
            return
        }

        let cursorOffset = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)
        onChangeText?(textView.text, cursorOffset, textView.textInputMode?.primaryLanguage)
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        entering = true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        entering = false
    }

}

extension MnemonicInputCell {

    func cellHeight(containerWidth: CGFloat) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalMargin - 2 * textViewInset - 2 * textView.textContainer.lineFragmentPadding
        let textHeight = textForHeight.height(forContainerWidth: textWidth, font: textViewFont)
        return max(Self.minimalTextViewHeight, textHeight + 2 * textViewInset)
    }

    func set(invalidRanges: [NSRange]) {
        let attributedString = NSMutableAttributedString(string: textView.text, attributes: [
            .foregroundColor: textViewTextColor,
            .font: textViewFont
        ])

        for range in invalidRanges {
            attributedString.addAttribute(.foregroundColor, value: UIColor.themeLucian, range: range)
        }

        let range = textView.selectedRange
        textView.attributedText = attributedString
        textView.selectedRange = range
    }

    func replaceWord(range: NSRange, word: String) {
        var text: String = textView.text

        guard let textRange = Range(range, in: text) else {
            return
        }

        let replaceWord = word + " "
        text.replaceSubrange(textRange, with: replaceWord)

        textForHeight = text
        textView.text = text

        let cursorOffset = range.lowerBound + replaceWord.count
        if let newPosition = textView.position(from: textView.beginningOfDocument, offset: cursorOffset) {
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
        }

        onChangeText?(text, cursorOffset, textView.textInputMode?.primaryLanguage)
    }

    func set(text: String) {
        textForHeight = text
        textView.text = text
        onChangeText?(text, text.count, textView.textInputMode?.primaryLanguage)
    }

    func set(cautionType: CautionType?) {
        let borderColor: UIColor

        if let cautionType = cautionType {
            borderColor = cautionType.borderColor
        } else {
            borderColor = .themeSteel20
        }

        borderView.layer.borderColor = borderColor.cgColor
    }

}
