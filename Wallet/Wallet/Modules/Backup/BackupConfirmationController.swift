import UIKit

class BackupConfirmationController: UIViewController {

    let delegate: IBackupViewDelegate
    let indexes: [Int]

    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var firstIndexLabel: UILabel?
    @IBOutlet weak var secondIndexLabel: UILabel?
    @IBOutlet weak var firstTextField: UITextField?
    @IBOutlet weak var secondTextField: UITextField?
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var confirmButton: UIButton?

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

        descriptionLabel?.text = "backup.confirmation.description".localized
        backButton?.setTitle("backup.confirmation.back".localized, for: .normal)
        confirmButton?.setTitle("backup.confirmation.confirm".localized, for: .normal)

        firstIndexLabel?.text = "\(indexes[0])."
        secondIndexLabel?.text = "\(indexes[1])."
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func confirmDidTap() {
        if let firstWord = firstTextField?.text, let secondWord = secondTextField?.text {
            delegate.validateDidClick(confirmationWords: [indexes[0]: firstWord, indexes[1]: secondWord])
        }
    }

    @IBAction func backDidTap() {
        delegate.hideConfirmationDidClick()
    }

    func showValidationFailure() {
        let alert = UIAlertController(title: nil, message: "backup.confirmation.failure_alert.text".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "alert.ok".localized, style: .default))
        present(alert, animated: true)
    }

}
