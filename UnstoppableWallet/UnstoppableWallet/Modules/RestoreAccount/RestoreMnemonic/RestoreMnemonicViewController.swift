import ThemeKit
import RxSwift
import RxCocoa

class RestoreMnemonicViewController: KeyboardAwareViewController {
    private let viewModel: RestoreMnemonicViewModel
    private let disposeBag = DisposeBag()

    private let minimalTextViewHeight: CGFloat = 88
    private let textViewInset: CGFloat = .margin12
    private let textViewTextColor: UIColor = .themeOz
    private let textViewFont: UIFont = .body

    private let scrollView = UIScrollView()
    private let textView = UITextView()

    init(viewModel: RestoreMnemonicViewModel) {
        self.viewModel = viewModel

        super.init(scrollView: scrollView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.enter_key".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .done, target: self, action: #selector(onTapProceedButton))

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        let contentView = UIView()

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(self.view)
        }

        contentView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view).inset(CGFloat.margin16)
            maker.top.equalToSuperview().offset(CGFloat.margin12)
            maker.height.greaterThanOrEqualTo(minimalTextViewHeight).priority(.required)
            maker.height.equalTo(0).priority(.low)
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

        textView.delegate = self

        let descriptionView = BottomDescriptionView()
        descriptionView.bind(text: "restore.mnemonic.description".localized)

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view)
            maker.top.equalTo(textView.snp.bottom)
            maker.bottom.equalToSuperview()
        }

        descriptionView.setContentCompressionResistancePriority(.required, for: .vertical)

        subscribe(disposeBag, viewModel.invalidRangesDriver) { [weak self] invalidRanges in
            self?.handle(invalidRanges: invalidRanges)
        }
        subscribe(disposeBag, viewModel.showErrorSignal) { error in
            HudHelper.instance.showError(title: error)
        }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] accountType in
            self?.openSelectCoins(accountType: accountType)
        }

        showDefaultWords()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async  {
            self.textView.becomeFirstResponder()
        }
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapProceedButton() {
        viewModel.onTapProceed()
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

    private func handle(invalidRanges: [NSRange]) {
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

    private func showDefaultWords() {
        let text = App.shared.appConfigProvider.defaultWords

        textView.text = text

        DispatchQueue.main.async {
            self.updateTextViewConstraints(for: text, animated: false)
        }

        viewModel.onChange(text: text, cursorOffset: text.count)
    }

    private func openSelectCoins(accountType: AccountType) {
        let viewController = RestoreSelectModule.viewController(accountType: accountType)
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension RestoreMnemonicViewController: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        updateTextViewConstraints(for: newText)

        return true
    }

    public func textViewDidChange(_ textView: UITextView) {
        syncContentOffsetIfRequired(textView: textView)

        guard let selectedTextRange = textView.selectedTextRange else {
            return
        }

        let cursorOffset = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)

        viewModel.onChange(text: textView.text, cursorOffset: cursorOffset)
    }

}
