import UIKit

class BackupConfirmationController: UIViewController {

    let delegate: IBackupViewDelegate
    let indexes: [Int]

    @IBOutlet weak var firstIndexedInputField: IndexedInputField?
    @IBOutlet weak var secondIndexedInputField: IndexedInputField?

    @IBOutlet weak var descriptionLabel: UILabel?

    init(indexes: [Int], delegate: IBackupViewDelegate) {
        self.indexes = indexes
        self.delegate = delegate

        super.init(nibName: String(describing: BackupConfirmationController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.confirmation.title".localized
        descriptionLabel?.text = "backup.confirmation.description".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "done".localized, style: .plain, target: self, action: #selector(confirmDidTap))

        firstIndexedInputField?.textField.returnKeyType = .next
        firstIndexedInputField?.onReturn = { [weak self] in
            self?.firstIndexedInputField?.textField.resignFirstResponder()
            self?.secondIndexedInputField?.textField.becomeFirstResponder()
        }
        secondIndexedInputField?.textField.returnKeyType = .done
        secondIndexedInputField?.onReturn = { [weak self] in
            self?.confirmDidTap()
        }

        firstIndexedInputField?.indexLabel.text = "\(indexes[0])."
        secondIndexedInputField?.indexLabel.text = "\(indexes[1])."
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firstIndexedInputField?.textField.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc func confirmDidTap() {
        if let firstWord = firstIndexedInputField?.textField.text, let secondWord = secondIndexedInputField?.textField.text {
            delegate.validateDidClick(confirmationWords: [indexes[0]: firstWord, indexes[1]: secondWord])
        }
    }

    func showValidationFailure() {
        let alert = UIAlertController(title: nil, message: "backup.confirmation.failure_alert.text".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "alert.ok".localized, style: .default))
        present(alert, animated: true)
    }

}
