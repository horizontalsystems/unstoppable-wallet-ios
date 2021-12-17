import UIKit
import ThemeKit
import SnapKit

class MnemonicInputCell: UITableViewCell {
    private static let minimalTextViewHeight: CGFloat = 88

    private let horizontalMargin: CGFloat = .margin16
    private let textViewInset: CGFloat = .margin12
    private let textViewFont: UIFont = .body
    private let textViewTextColor: UIColor = .themeOz

    private let textView = UITextView()

    var onChangeHeight: (() -> ())?
    var onChangeText: ((String, Int) -> ())?
    var onChangeTextViewCaret: ((UITextView) -> ())?

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
        textView.layer.borderWidth = .heightOneDp
        textView.layer.borderColor = UIColor.themeSteel20.cgColor
        textView.textColor = textViewTextColor
        textView.font = textViewFont
        textView.tintColor = .themeJacob
        textView.textContainerInset = UIEdgeInsets(top: textViewInset, left: textViewInset, bottom: textViewInset, right: textViewInset)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no

        textView.delegate = self
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

        onChangeText?(textView.text, cursorOffset)
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

    func set(text: String) {
        textForHeight = text
        textView.text = text
        onChangeText?(text, text.count)
    }

}
