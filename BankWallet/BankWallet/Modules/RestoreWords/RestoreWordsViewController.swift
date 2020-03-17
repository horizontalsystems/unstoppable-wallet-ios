import UIKit
import ThemeKit

class RestoreWordsViewController: ThemeKit.RestoreWordsViewController {
    private let delegate: IRestoreWordsViewDelegate

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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "button.back".localized, style: .plain, target: nil, action: nil)

        delegate.viewDidLoad()
    }

    override var descriptionText: String? {
        // temp solution until multi-wallet feature is implemented
        let predefinedAccountType: PredefinedAccountType = delegate.wordsCount == 12 ? .standard : .binance
        return "restore.words.description".localized(predefinedAccountType.title, String(delegate.wordsCount))
    }

    @objc private func restoreDidTap() {
        view.endEditing(true)

        delegate.didTapRestore(words: words)
    }

    @objc private func cancelDidTap() {
        delegate.didTapCancel()
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

    func showDoneButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(restoreDidTap))
    }

}
