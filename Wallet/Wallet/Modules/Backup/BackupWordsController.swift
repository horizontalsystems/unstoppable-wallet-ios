import UIKit

class BackupWordsController: UIViewController {

    let viewDelegate: BackupViewDelegate

    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var wordsLabel: UILabel?
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var proceedButton: UIButton?

    let words: [String]

    init(words: [String], viewDelegate: BackupViewDelegate) {
        self.words = words
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: BackupWordsController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionLabel?.text = "backup.words.description".localized
        backButton?.setTitle("backup.words.back".localized, for: .normal)
        proceedButton?.setTitle("backup.words.proceed".localized, for: .normal)

        wordsLabel?.text = words.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func nextDidTap() {
        viewDelegate.showConfirmationDidTap()
    }

    @IBAction func backDidTap() {
        viewDelegate.hideWordsDidTap()
    }

}
