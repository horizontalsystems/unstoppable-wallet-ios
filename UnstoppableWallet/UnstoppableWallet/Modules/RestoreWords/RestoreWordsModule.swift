protocol IRestoreWordsView: class {
    func showNextButton()
    func showRestoreButton()

    func show(defaultWords: [String])
    func show(error: Error)
}

protocol IRestoreWordsViewDelegate {
    var wordsCount: Int { get }
    func viewDidLoad()
    func didTapRestore(words: [String])
    func didTapCancel()
}
