import UIKit

class BackupWordsController: UIViewController {

    let viewDelegate: BackupViewDelegate

    @IBOutlet weak var wordsLabel: UILabel?
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
