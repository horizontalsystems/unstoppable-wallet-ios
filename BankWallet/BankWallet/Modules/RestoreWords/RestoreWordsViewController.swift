import UIKit
import RxSwift
import SnapKit

class RestoreWordsViewController: WalletViewController {
    private let delegate: IRestoreWordsViewDelegate

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

        title = "restore.enter_key".localized

        let textViewFont: UIFont = .appBody
        let textViewMargin: CGFloat = .margin3x

        textView.keyboardAppearance = App.theme.keyboardAppearance
        textView.backgroundColor = .crypto_SteelDark_White
        textView.layer.cornerRadius = .cornerRadius8
        textView.layer.borderWidth = .heightOnePixel
        textView.layer.borderColor = UIColor.appSteel20.cgColor
        textView.textColor = .appOz
        textView.font = textViewFont
        textView.tintColor = .appJacob
        textView.textContainerInset = UIEdgeInsets(top: textViewMargin, left: textViewMargin, bottom: textViewMargin, right: textViewMargin)
        textView.autocapitalizationType = .none

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(view.snp.topMargin).offset(CGFloat.margin3x)
            maker.height.equalTo(88)
        }

        // temp solution until multi-wallet feature is implemented
        let predefinedAccountType: IPredefinedAccountType = delegate.wordsCount == 12 ? UnstoppableAccountType() : BinanceAccountType()

        let descriptionView = BottomDescriptionView()
        descriptionView.bind(text: "restore.words.description".localized(predefinedAccountType.title, String(delegate.wordsCount)))

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(textView.snp.bottom)
        }

        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async  {
            self.textView.becomeFirstResponder()
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
        textView.text = defaultWords.joined(separator: " ")
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}
