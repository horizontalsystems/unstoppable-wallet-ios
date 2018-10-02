import UIKit
import SnapKit

class PinViewController: KeyboardObservingViewController {
    let delegate: IPinViewDelegate

    var holderView = UIScrollView()

    var pages = [PinPage]()
    var pinViews = [PinView]()
    var didAppear = false

    init(delegate: IPinViewDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = AppTheme.controllerBackground

        let dumbView = UIView()
        view.addSubview(dumbView)

        view.addSubview(holderView)
        holderView.isScrollEnabled = false
        holderView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            maker.leading.trailing.bottom.equalToSuperview()
        }
        holderView.backgroundColor = .clear

        super.viewDidLoad()
        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppear = true
    }

    override func updateUI(keyboardHeight: CGFloat, duration: TimeInterval, options: UIViewAnimationOptions, completion: (() -> ())?) {
        holderView.snp.updateConstraints { maker in
            maker.bottom.equalToSuperview().offset(-keyboardHeight)
        }
        if duration > 0, didAppear {
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: { [weak self] in
                self?.view.window?.layoutIfNeeded()
            })
        }
    }

    @objc func onCancelTap() {
        delegate.onCancel()
    }

    func reload(at index: Int) {
        pinViews[index].bind(page: pages[index]) { [weak self] pin in
            self?.delegate.onEnter(pin: pin, forPage: index)
        }
    }

}

extension PinViewController: IPinView {

    func set(title: String) {
        self.title = title.localized
    }

    func addPage(withDescription description: String, showKeyboard: Bool) {
        let page = PinPage(description: description, showKeyboard: showKeyboard)
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

    func showKeyboard(for index: Int) {
        pinViews[index].becomeFirstResponder()
    }

    func showCancel() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "alert.cancel".localized, style: .plain, target: self, action: #selector(onCancelTap))
    }

1    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

}

struct PinPage {
    var description: String?
    var error: String?
    var showKeyboard: Bool = false

    init(description: String) {
        self.description = description
    }

    init(description: String, showKeyboard: Bool) {
        self.description = description
        self.showKeyboard = showKeyboard
    }

}
