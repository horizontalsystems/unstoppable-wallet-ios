import UIKit

class RestoreViewController: UIViewController {

    let viewDelegate: RestoreViewDelegate

    @IBOutlet weak var wordsTextView: UITextView?
    @IBOutlet weak var descriptionLabel: UILabel?

    init(viewDelegate: RestoreViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: RestoreViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.title".localized
        descriptionLabel?.text = "restore.description".localized

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "navigation_bar.cancel".localized, style: .plain, target: self, action: #selector(cancelDidTap))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "restore.restore".localized, style: .plain, target: self, action: #selector(restoreDidTap))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc func cancelDidTap() {
        viewDelegate.cancelDidTap()
    }

    @objc func restoreDidTap() {
        let wordsString = wordsTextView?.text ?? ""
        viewDelegate.restoreDidTap(withWords: wordsString.split(separator: " ").map(String.init))
    }

}

extension RestoreViewController: RestoreViewProtocol {

    func showWordsValidationFailure() {
        let alert = UIAlertController(title: nil, message: "restore.validation_failed".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "alert.ok".localized, style: .default))
        present(alert, animated: true)
    }

}
