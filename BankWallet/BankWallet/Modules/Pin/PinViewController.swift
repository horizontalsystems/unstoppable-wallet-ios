import UIKit
import SnapKit

class PinViewController: WalletViewController {
    let delegate: IPinViewDelegate

    private let holderView = UIScrollView()
    private let numPad = NumPad(style: [.letters])

    private var pages = [PinPage]()
    private var pinViews = [PinView]()

    private let lockoutView = LockoutView()

    private let insets: UIEdgeInsets
    private let useSafeAreaLayoutGuide: Bool

    private var currentPage = 0

    init(delegate: IPinViewDelegate, gradient: Bool = true, insets: UIEdgeInsets = .zero, useSafeAreaLayoutGuide: Bool = true) {
        self.delegate = delegate
        self.insets = insets
        self.useSafeAreaLayoutGuide = useSafeAreaLayoutGuide

        super.init(gradient: gradient)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(holderView)
        holderView.isScrollEnabled = false
        holderView.snp.makeConstraints { maker in
            let constraint: ConstraintRelatableTarget = self.useSafeAreaLayoutGuide ? self.view.safeAreaLayoutGuide.snp.top : self.view
            maker.top.equalTo(constraint).offset(insets.top)
            maker.leading.equalToSuperview().offset(insets.left)
            maker.trailing.equalToSuperview().offset(-insets.right)
        }
        holderView.backgroundColor = .clear

        view.addSubview(numPad)
        numPad.snp.makeConstraints { maker in
            let constraint: ConstraintRelatableTarget = self.useSafeAreaLayoutGuide ? self.view.safeAreaLayoutGuide.snp.bottom : self.view
            maker.top.equalTo(self.holderView.snp.bottom)
            maker.bottom.equalTo(constraint).offset(-insets.bottom)
            maker.leading.equalToSuperview().offset(PinTheme.keyboardSideMargin + insets.left)
            maker.trailing.equalToSuperview().inset(PinTheme.keyboardSideMargin + insets.right)
            maker.height.equalTo(numPad.height(for: view.bounds.width - 2 * PinTheme.keyboardSideMargin - insets.width))
        }

        numPad.numPadDelegate = self

        view.addSubview(lockoutView)
        lockoutView.hide()
        lockoutView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    @objc func onCancelTap() {
        delegate.onCancel()
    }

    func reload(at index: Int) {
        pinViews[index].bind(page: pages[index]) { [weak self] pin in
            self?.delegate.onEnter(pin: pin, forPage: index)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return App.theme.statusBarStyle
    }

}

extension PinViewController: NumPadDelegate {

    func numPadDidClick(digit: String) {
        pinViews[currentPage].pinDotsView.append(digit: digit)
    }

    func numPadDidClickBackspace() {
        pinViews[currentPage].pinDotsView.removeLastDigit()
    }

}

extension PinViewController: IPinView {

    func set(title: String) {
        self.title = title.localized
    }

    func addPage(withDescription description: String) {
        let page = PinPage(description: description)
        pages.append(page)

        let pinView = PinView()
        pinViews.append(pinView)

        reload(at: pinViews.count - 1)

        holderView.addSubview(pinView)
        var previousView: UIView?
        for view in holderView.subviews {
            view.snp.remakeConstraints { maker in
                maker.width.height.equalToSuperview()
                maker.top.bottom.equalTo(self.holderView)

                if view == holderView.subviews.first {
                    maker.leading.equalToSuperview()
                } else if view == holderView.subviews.last {
                    maker.trailing.equalToSuperview()
                }
                if let previousView = previousView {
                    maker.leading.equalTo(previousView.snp.trailing)
                }
            }
            previousView = view
        }
        view.layoutIfNeeded()
    }

    func show(page index: Int) {
        currentPage = index

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.holderView.setContentOffset(CGPoint(x: index * Int(UIScreen.main.bounds.width), y: 0), animated: true)
            self.reload(at: index)
        }
    }

    func show(error: String, forPage index: Int) {
        pages[index].error = error.localized
        reload(at: index)
    }

    func show(error: String) {
        HudHelper.instance.showError(title: error.localized)
    }

    func showPinWrong(page index: Int) {
        pinViews[index].shakeAndClear()
    }

    func showCancel() {
        if navigationController?.isNavigationBarHidden ?? true {
            pinViews[currentPage].showCancelButton(target: self, action: #selector(onCancelTap))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onCancelTap))
        }
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

    func showLockView(till date: Date) {
        lockoutView.show(expirationDate: date)
    }

    func show(attemptsLeft: Int?, forPage index: Int) {
        lockoutView.hide()
    }

}

struct PinPage {
    var description: String?
    var error: String?

    init(description: String) {
        self.description = description
    }

}
