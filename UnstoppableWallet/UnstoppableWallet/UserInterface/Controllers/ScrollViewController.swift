import ThemeKit
import RxSwift
import RxCocoa

class ScrollViewController: ThemeViewController {
    let scrollView = UIScrollView()
    let contentView = UIView()

    private var translucentContentOffset: CGFloat = 0
    private var keyboardFrame: CGRect?

    init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(self.view)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        translucentContentOffset = scrollView.contentOffset.y
    }

    func updateScrollView() {
        guard let responder = firstResponder(view: contentView) as? UITextInput,
              let responderView = responder as? UIView,
              let keyboardFrame = keyboardFrame,
              keyboardFrame.origin.y < view.height else {

            return
        }
        var shift: CGFloat = 0
        if let cursorPosition = responder.selectedTextRange?.start {
            let caretPositionFrame: CGRect = responderView.convert(responder.caretRect(for: cursorPosition), to: nil)
            let caretVisiblePosition = caretPositionFrame.origin.y - .margin2x + translucentContentOffset

            if caretVisiblePosition < 0 {
                shift = caretVisiblePosition + scrollView.contentOffset.y
            } else {
                shift = max(0, caretPositionFrame.origin.y + caretPositionFrame.height + .margin2x - keyboardFrame.origin.y) + scrollView.contentOffset.y
            }
        }

        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height - view.safeAreaInsets.bottom, right: 0)
        scrollView.setContentOffset(CGPoint(x: 0, y: shift), animated: true)
    }

    func firstResponder(view: UIView) -> UIView? {
        for subview in view.subviews {
            if let result = firstResponder(view: subview) {
                return result
            }
        }
        return view.isFirstResponder ? view : nil
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let oldKeyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
              let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              oldKeyboardFrame != keyboardFrame else {
            return
        }
        self.keyboardFrame = keyboardFrame
        updateScrollView()
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        keyboardFrame = nil
        scrollView.contentInset = .zero
    }

}
