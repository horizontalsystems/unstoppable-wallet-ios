import UIKit
import RxSwift
import SectionsTableView

class SendNewViewController: UIViewController, SectionsDataSource {
    private let disposeBag = DisposeBag()

    private let delegate: ISendViewDelegate

    private var keyboardFrameDisposable: Disposable?

    let iconImageView = UIImageView()
    let tableView = SectionsTableView(style: .grouped)

    init(delegate: ISendViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tableView.registerCell(forClass: SendAmountCell.self)
        tableView.registerCell(forClass: SendAddressCell.self)
        tableView.registerCell(forClass: SendFeeCell.self)
        tableView.registerCell(forClass: SendButtonCell.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = .clear
        tableView.delaysContentTouches = false

    }

    @objc func onClose() {
        delegate.onClose()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        subscribeKeyboard()

        view.backgroundColor = AppTheme.controllerBackground

        iconImageView.tintColor = .cryptoGray

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Close Full Transaction Icon"), style: .plain, target: self, action: #selector(onClose))

        tableView.backgroundColor = .clear
//        tableView.alwaysBounceVertical = false
        tableView.keyboardDismissMode = .interactive

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.onViewDidLoad()

        tableView.reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if keyboardFrameDisposable == nil {
            subscribeKeyboard()
        }

        delegate.showKeyboard()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        let items = delegate.sendItems
        var rows = [RowProtocol]()
        items.forEach { item in
            if let item = item as? AmountItem {
                rows.append(Row<SendAmountCell>(id: "amount", height: SendTheme.amountHeight, bind: { cell, _ in
                    cell.bind(item: item)
                }))
            } else if let item = item as? SAddressItem {
                rows.append(Row<SendAddressCell>(id: "address", height: SendTheme.addressHeight, bind: { cell, _ in
                    cell.bind(item: item)
                }))
            } else if let item = item as? SFeeItem {
                rows.append(Row<SendFeeCell>(id: "fee", height: SendTheme.feeHeight, bind: { cell, _ in
                    cell.bind(item: item)
                }))
            } else if let item = item as? SButtonItem {
                rows.append(Row<SendButtonCell>(id: "send_button", height: SendTheme.sendHeight, bind: { cell, _ in
                    cell.bind(item: item)
                }))
            }
        }
        sections.append(Section(id: "model", rows: rows))

        return sections
    }

    private func subscribeKeyboard() {
        keyboardFrameDisposable = NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] notification in
                    self?.onKeyboardFrameChange(notification)
                })
        keyboardFrameDisposable?.disposed(by: disposeBag)
    }

    private func onKeyboardFrameChange(_ notification: Notification) {
        let screenKeyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let height = view.height + view.y
        let keyboardHeight = height - screenKeyboardFrame.origin.y

        let duration = (notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let curve = (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue

        updateUI(keyboardHeight: keyboardHeight, duration: duration, options: UIView.AnimationOptions(rawValue: curve << 16))
    }

    private func updateUI(keyboardHeight: CGFloat, duration: TimeInterval, options: UIView.AnimationOptions, completion: (() -> ())? = nil) {
        var insets: UIEdgeInsets = tableView.contentInset
        insets.bottom = keyboardHeight + RestoreTheme.listBottomMargin
        tableView.contentInset = insets
    }

}

extension SendNewViewController: ISendView {

    func set(coin: Coin) {
        title = "send.title".localized(coin.title)
        iconImageView.image = UIImage(named: "\(coin.code.lowercased())")?.withRenderingMode(.alwaysTemplate)
    }

    func showConfirmation(viewItem: SendConfirmationViewItem) {
        let confirmationController = SendConfirmationViewController(delegate: delegate, viewItem: viewItem)
        present(confirmationController, animated: true)
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

    func showProgress() {
        HudHelper.instance.showSpinner(userInteractionEnabled: false)
    }

    func dismissWithSuccess() {
        presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.dismiss(animated: true)
        })
        HudHelper.instance.showSuccess()
    }

}
