import ThemeKit
import RxSwift
import RxCocoa

class RestoreWordsViewController: ScrollViewController {
    private let restoreView: RestoreView
    private let viewModel: RestoreWordsViewModel

    private let minimalTextViewHeight: CGFloat = 88
    private let textViewInset: CGFloat = .margin3x
    private let textViewFont: UIFont = .body

    private let textView = UITextView()
    private var birthdayTextView: InputFieldStackView?

    private let disposeBag = DisposeBag()

    init(restoreView: RestoreView, viewModel: RestoreWordsViewModel) {
        self.restoreView = restoreView
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.enter_key".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "button.back".localized, style: .plain, target: nil, action: nil)

        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(cancelDidTap))
        }

        if restoreView.viewModel.selectCoins {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .plain, target: self, action: #selector(proceedDidTap))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(proceedDidTap))
        }

        navigationItem.largeTitleDisplayMode = .never

        contentView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view).inset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.height.greaterThanOrEqualTo(minimalTextViewHeight).priority(.required)
            maker.height.equalTo(0).priority(.low)
        }

        textView.keyboardAppearance = .themeDefault
        textView.backgroundColor = .themeLawrence
        textView.layer.cornerRadius = .cornerRadius2x
        textView.layer.borderWidth = .heightOnePixel
        textView.layer.borderColor = UIColor.themeSteel20.cgColor
        textView.tintColor = .themeJacob
        textView.textContainerInset = UIEdgeInsets(top: textViewInset, left: textViewInset, bottom: textViewInset, right: textViewInset)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no

        textView.delegate = self

        let descriptionView = BottomDescriptionView()
        descriptionView.bind(text: descriptionText)

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view)
            maker.top.equalTo(textView.snp.bottom)
            if !viewModel.birthdayHeightEnabled {
                maker.bottom.equalToSuperview()
            }
        }

        descriptionView.setContentCompressionResistancePriority(.required, for: .vertical)

        if viewModel.birthdayHeightEnabled {
            let wrapperView = UIView()
            contentView.addSubview(wrapperView)
            wrapperView.snp.makeConstraints { maker in
                maker.leading.trailing.equalTo(view).inset(CGFloat.margin4x)
                maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin3x)
                maker.height.equalTo(CGFloat.heightSingleLineCell)
            }

            wrapperView.backgroundColor = .themeLawrence
            wrapperView.layer.cornerRadius = .cornerRadius2x
            wrapperView.layer.borderWidth = CGFloat.heightOnePixel
            wrapperView.layer.borderColor = UIColor.themeSteel20.cgColor

            let inputFieldView = InputFieldStackView()

            wrapperView.addSubview(inputFieldView)
            inputFieldView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin3x)
                maker.top.bottom.equalToSuperview()
            }

            inputFieldView.decimalKeyboard = true
            inputFieldView.isValidText = { text in
                Int(text) != nil
            }
            inputFieldView.set(placeholder: "restore.birthday_height.placeholder".localized)
            inputFieldView.onChangeText = { [weak self] text in
                self?.viewModel.onChange(birthdayHeight: text)
            }

            birthdayTextView = inputFieldView

            let descriptionView = BottomDescriptionView()
            descriptionView.bind(text: "restore.birthday_height.description".localized)

            contentView.addSubview(descriptionView)
            descriptionView.setContentCompressionResistancePriority(.required, for: .vertical)
            descriptionView.snp.makeConstraints { maker in
                maker.leading.trailing.equalTo(view)
                maker.top.equalTo(wrapperView.snp.bottom)
                maker.bottom.equalToSuperview()
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        view.layoutIfNeeded()

        subscribe(disposeBag, viewModel.invalidRangesDriver) { [weak self] invalidRanges in
            self?.handle(invalidRanges: invalidRanges)
        }
        subscribe(disposeBag, viewModel.errorSignal) { error in
            HudHelper.instance.showError(title: error)
        }
        subscribe(disposeBag, viewModel.accountTypeSignal) { [weak self] accountType in
            self?.restoreView.viewModel.onEnter(accountType: accountType)
        }

        showDefaultWords()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !viewModel.birthdayHeightEnabled {
            DispatchQueue.main.async  {
                self.textView.becomeFirstResponder()
            }
        }
    }

    private func height(text: String) -> CGFloat {
        let containerWidth = textView.bounds.width - 2 * textViewInset - 2 * textView.textContainer.lineFragmentPadding
        let textHeight = text.height(forContainerWidth: containerWidth, font: textViewFont)
        return textHeight + 2 * textViewInset
    }

    private func updateTextViewConstraints(for text: String, animated: Bool = true) {
        textView.snp.updateConstraints { maker in
            maker.height.equalTo(height(text: text)).priority(.low)
        }

        if animated {
            UIView.animate(withDuration: .themeAnimationDuration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    private var descriptionText: String? {
//        temp solution until multi-wallet feature is implemented
        "restore.words.description".localized(viewModel.accountTitle, String(viewModel.wordCount))
    }

    @objc private func proceedDidTap() {
        viewModel.onTapProceed()
    }

    @objc private func cancelDidTap() {
        dismiss(animated: true)
    }

    private func handle(invalidRanges: [NSRange]) {
        let attributedString = NSMutableAttributedString(string: textView.text, attributes: [
            .foregroundColor: UIColor.themeOz,
            .font: textViewFont
        ])

        for range in invalidRanges {
            attributedString.addAttribute(.foregroundColor, value: UIColor.themeLucian, range: range)
        }

        let range = textView.selectedRange
        textView.attributedText = attributedString
        textView.selectedRange = range
    }

    private func showDefaultWords() {
        let text = App.shared.appConfigProvider.defaultWords(count: viewModel.wordCount)

        textView.text = text

        DispatchQueue.main.async {
            self.updateTextViewConstraints(for: text, animated: false)
        }

        viewModel.onChange(text: text, cursorOffset: text.count)
    }

}

extension RestoreWordsViewController: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        updateTextViewConstraints(for: newText)

        return true
    }

    public func textViewDidChange(_ textView: UITextView) {
        updateScrollView()

        guard let selectedTextRange = textView.selectedTextRange else {
            return
        }

        let cursorOffset = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)

        viewModel.onChange(text: textView.text, cursorOffset: cursorOffset)
    }

}
