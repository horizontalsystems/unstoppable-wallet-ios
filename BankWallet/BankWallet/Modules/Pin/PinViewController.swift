import UIKit
import SnapKit

class PinViewController: UIViewController {
    let delegate: IPinViewDelegate

    private let holderView = UIScrollView()
    private let numPad = NumPad()

    private var pages = [PinPage]()
    private var pinViews = [PinView]()

    private var currentPage = 0

    init(delegate: IPinViewDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = AppTheme.controllerBackground

        view.addSubview(holderView)
        holderView.isScrollEnabled = false
        holderView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            maker.leading.trailing.equalToSuperview()
        }
        holderView.backgroundColor = .clear

        view.addSubview(numPad)
        numPad.snp.makeConstraints { maker in
            maker.top.equalTo(self.holderView.snp.bottom)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-32)
            maker.centerX.equalToSuperview()
        }

        numPad.numPadDelegate = self

        super.viewDidLoad()
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
        return AppTheme.statusBarStyle
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
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "alert.cancel".localized, style: .plain, target: self, action: #selector(onCancelTap))
        }
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

    func showLockView(till date: Date) {
        show(error: "u r blocked till: \(date)")
    }

    func show(attemptsLeft: Int?, forPage index: Int) {
        if let attemptsLeft = attemptsLeft {
            show(error: "unlock_pin.wrong_pin.attempts_left".localized("\(attemptsLeft)"), forPage: index)
        }
    }

}

struct PinPage {
    var description: String?
    var error: String?

    init(description: String) {
        self.description = description
    }

}
