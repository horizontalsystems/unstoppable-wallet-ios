import ThemeKit

class KeyboardAwareViewController: ThemeViewController {
    private let scrollViews: [UIScrollView]

    private var translucentContentOffset: CGFloat = 0
    private var keyboardFrame: CGRect?

    init(scrollViews: [UIScrollView]) {
        self.scrollViews = scrollViews

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for scrollView in scrollViews {
            scrollView.alwaysBounceVertical = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.keyboardDismissMode = .interactive
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        translucentContentOffset = scrollViews[0].contentOffset.y
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let oldKeyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
              let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              oldKeyboardFrame != keyboardFrame else {
            return
        }

        self.keyboardFrame = keyboardFrame

        for scrollView in scrollViews {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height - view.safeAreaInsets.bottom, right: 0)
            scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        keyboardFrame = nil

        for scrollView in scrollViews {
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
        }
    }

    func syncContentOffsetIfRequired(textView: UITextView) {
        guard let keyboardFrame = keyboardFrame else {
            return
        }

        var shift: CGFloat = 0

        if let cursorPosition = textView.selectedTextRange?.start {
            let caretPositionFrame: CGRect = textView.convert(textView.caretRect(for: cursorPosition), to: nil)
            let caretVisiblePosition = caretPositionFrame.origin.y - .margin2x + translucentContentOffset

            if caretVisiblePosition < 0 {
                shift = caretVisiblePosition + scrollViews[0].contentOffset.y
            } else {
                shift = max(0, caretPositionFrame.origin.y + caretPositionFrame.height + .margin2x - keyboardFrame.origin.y) + scrollViews[0].contentOffset.y
            }
        }

        scrollViews[0].setContentOffset(CGPoint(x: 0, y: shift), animated: true)
    }

}
