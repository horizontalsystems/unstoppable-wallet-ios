import UIKit

class BackupWordsController: UIViewController {

    let delegate: IBackupViewDelegate

    @IBOutlet weak var wordsLabel: UILabel?
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var proceedButton: UIButton?

    let words: [String]

    init(words: [String], delegate: IBackupViewDelegate) {
        self.words = words
        self.delegate = delegate

        super.init(nibName: String(describing: BackupWordsController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.words.title".localized

        backButton?.setTitle("backup.words.back".localized, for: .normal)
        proceedButton?.setTitle("backup.words.proceed".localized, for: .normal)

        let joinedWords = words.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
        let attributedText = wordsLabel?.attributedText as? NSMutableAttributedString
        attributedText?.mutableString.setString(joinedWords)
        attributedText?.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 22, weight: .bold), range: NSMakeRange(0, joinedWords.count))
        wordsLabel?.attributedText = attributedText

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func nextDidTap() {
        delegate.showConfirmationDidClick()
    }

    @IBAction func backDidTap() {
        delegate.hideWordsDidClick()
    }

}
