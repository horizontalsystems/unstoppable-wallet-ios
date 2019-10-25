import UIKit
import RxSwift
import SnapKit

class RestoreWordsViewController: WalletViewController {
    private static let minimalTextViewHeight: CGFloat = 88
    private static let textViewInset: CGFloat = .margin3x

    private let disposeBag = DisposeBag()
    private let delegate: IRestoreWordsViewDelegate

    private let containerView = UIView()
    private let textView = UITextView()

    init(delegate: IRestoreWordsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        title = "restore.enter_key".localized

        view.addSubview(containerView)
        containerView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        let textViewFont: UIFont = .appBody

        textView.keyboardAppearance = App.theme.keyboardAppearance
        textView.backgroundColor = .crypto_SteelDark_White
        textView.layer.cornerRadius = .cornerRadius8
        textView.layer.borderWidth = .heightOnePixel
        textView.layer.borderColor = UIColor.appSteel20.cgColor
        textView.textColor = .appOz
        textView.font = textViewFont
        textView.tintColor = .appJacob
        textView.textContainerInset = UIEdgeInsets(top: RestoreWordsViewController.textViewInset, left: RestoreWordsViewController.textViewInset, bottom: RestoreWordsViewController.textViewInset, right: RestoreWordsViewController.textViewInset)
        textView.autocapitalizationType = .none

        textView.delegate = self

        containerView.addSubview(textView)
        textView.snp.remakeConstraints { maker in
            maker.leading.trailing.equalTo(view).inset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.height.greaterThanOrEqualTo(RestoreWordsViewController.minimalTextViewHeight).priority(.required)
            maker.height.equalTo(height(text: "")).priority(.low)
        }
        view.layoutIfNeeded()

        // temp solution until multi-wallet feature is implemented
        let predefinedAccountType: IPredefinedAccountType = delegate.wordsCount == 12 ? UnstoppableAccountType() : BinanceAccountType()

        let descriptionView = BottomDescriptionView()
        descriptionView.bind(text: "restore.words.description".localized(predefinedAccountType.title, String(delegate.wordsCount)))

        containerView.addSubview(descriptionView)
        descriptionView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view)
            maker.top.equalTo(textView.snp.bottom)
            maker.bottom.lessThanOrEqualToSuperview()
        }

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification).subscribe(onNext: { [weak self] notification in
            self?.keyboardWillChangeFrame(notification: notification)
        }).disposed(by: disposeBag)

        containerView.layoutIfNeeded()

        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async  {
            self.textView.becomeFirstResponder()
        }
    }

    private func keyboardWillChangeFrame(notification: Notification) {
        if let info = notification.userInfo,
           let endFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
                guard let superview = containerView.superview else {
                    return
                }
                let inset = endFrame.origin.y >= view.height ? 0 : endFrame.height
                containerView.snp.updateConstraints { maker in
                    maker.bottom.equalTo(self.view).inset(inset)
                }
                UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
                    superview.layoutIfNeeded()
                })
        }
    }

    @objc func restoreDidTap() {
        view.endEditing(true)

        delegate.didTapRestore(words: words)
    }

    @objc func cancelDidTap() {
        delegate.didTapCancel()
    }

    private var words: [String] {
        let text = textView.text ?? ""
        let components = text.components(separatedBy: .whitespacesAndNewlines)

        return components.filter { !$0.isEmpty }
    }

    private func height(text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: textView.bounds.width - 2 * RestoreWordsViewController.textViewInset, font: UIFont.appBody)
        return textHeight + 3 * RestoreWordsViewController.textViewInset
    }

    private func updateTextViewConstraints(for text: String, animated: Bool = true) {
        textView.snp.updateConstraints { maker in
            maker.height.equalTo(height(text: text)).priority(.low)
        }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

}

extension RestoreWordsViewController: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        updateTextViewConstraints(for: newText)

        return true
    }

}

extension RestoreWordsViewController: IRestoreWordsView {

    func showCancelButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(cancelDidTap))
    }

    func showNextButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .plain, target: self, action: #selector(restoreDidTap))
    }

    func showRestoreButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(restoreDidTap))
    }

    func show(defaultWords: [String]) {
        let words = defaultWords.joined(separator: " ")
        textView.text = words

        updateTextViewConstraints(for: words, animated: false)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}
