import UIKit
import SectionsTableViewKit
import GrouviExtensions
import GrouviHUD
import SnapKit

class FullTransactionInfoViewController: UIViewController, SectionsDataSource {
    private let cellName = String(describing: FullTransactionInfoTextCell.self)
    private let closeButtonImage = UIImage(named: "Close Full Transaction Icon")
    private let shareButtonImage = UIImage(named: "Share Full Transaction Icon")

    private let delegate: IFullTransactionInfoViewDelegate

    let tableView = SectionsTableView(style: .grouped)

    private let closeButton = UIButton(frame: .zero)
    private let shareButton = UIButton(frame: .zero)

    private var errorView: RequestErrorView?

    init(delegate: IFullTransactionInfoViewDelegate) {
        self.delegate = delegate


        super.init(nibName: nil, bundle: nil)

        errorView = RequestErrorView(title: "", subtitle: "offline", buttonText: "Retry", onTapButton: { [weak self] in
            self?.onRetry()
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.controllerBackground
        title = "full_info.title".localized

        view.addSubview(tableView)
        tableView.backgroundColor = .clear

        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: FullTransactionInfoTextCell.self)
        tableView.registerCell(forClass: SettingsCell.self)
        tableView.registerHeaderFooter(forClass: FullTransactionHeaderView.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = SettingsTheme.separatorColor
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: FullTransactionInfoTheme.bottomBarHeight))

        let blurEffect = UIBlurEffect(style: AppTheme.blurStyle)
        let holderView = UIVisualEffectView(effect: blurEffect)
        holderView.backgroundColor = .clear
        view.addSubview(holderView)

        holderView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
        }
        let separatorView = UIView()
        separatorView.backgroundColor = FullTransactionInfoTheme.separatorColor
        holderView.contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
        let toolbar = UIView(frame: .zero)
        holderView.contentView.addSubview(toolbar)

        toolbar.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview()
            maker.bottom.equalTo(holderView.contentView.safeAreaLayoutGuide)
            maker.height.equalTo(FullTransactionInfoTheme.bottomBarHeight)
        }

        toolbar.addSubview(closeButton)
        closeButton.setImage(closeButtonImage?.tinted(with: FullTransactionInfoTheme.bottomBarTintColor), for: .normal)
        closeButton.setImage(closeButtonImage?.tinted(with: FullTransactionInfoTheme.bottomHighlightBarTintColor), for: .highlighted)
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        closeButton.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalTo(toolbar.snp.trailingMargin)
            maker.width.equalTo(closeButton.snp.height)
        }

        toolbar.addSubview(shareButton)
        shareButton.setImage(shareButtonImage?.tinted(with: FullTransactionInfoTheme.bottomBarTintColor), for: .normal)
        shareButton.setImage(shareButtonImage?.tinted(with: FullTransactionInfoTheme.bottomHighlightBarTintColor), for: .highlighted)
        shareButton.addTarget(self, action: #selector(onShare), for: .touchUpInside)
        shareButton.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(toolbar.snp.leadingMargin)
            maker.width.equalTo(shareButton.snp.height)
        }

        if let errorView = errorView {
            view.addSubview(errorView)

            errorView.snp.makeConstraints { maker in
                maker.top.leading.equalToSuperview().offset(FullTransactionInfoTheme.errorViewMargin)
                maker.trailing.equalToSuperview().offset(-FullTransactionInfoTheme.errorViewMargin)
                maker.bottom.equalTo(toolbar.snp.top).offset(-FullTransactionInfoTheme.errorViewMargin)
            }
            errorView.set(hidden: true)
        }

        delegate.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        for sectionIndex in 0..<delegate.numberOfSections() {
            var sectionRows = [RowProtocol]()
            guard let section = delegate.section(sectionIndex) else {
                continue
            }
            for (rowIndex, item) in section.items.enumerated() {
                sectionRows.append(Row<FullTransactionInfoTextCell>(id: "section_\(sectionIndex)_row_\(rowIndex)", height: FullTransactionInfoTheme.cellHeight, bind: { cell, _ in
                    cell.separatorView.backgroundColor = FullTransactionInfoTheme.separatorColor

                    cell.bind(item: item, last: rowIndex == section.items.count - 1, onTap: item.clickable ? { [weak self] in
                        self?.onTap(item: item)
                    } : nil)
                }))
            }
            if let title = section.title {
                let header: ViewState<FullTransactionHeaderView> = .cellType(hash: "section_\(title)", binder: { view in
                    view.bind(title: title)
                }, dynamicHeight: { _ in FullTransactionInfoTheme.sectionHeight })
                sections.append(Section(id: "section_\(sectionIndex)", headerState: header, rows: sectionRows))
            } else {
                sections.append(Section(id: "section_\(sectionIndex)", headerState: .marginColor(height: FullTransactionInfoTheme.sectionEmptyMargin, color: .clear), rows: sectionRows))
            }
        }

        if let resource = delegate.resource {
            let header: ViewState<FullTransactionHeaderView> = .cellType(hash: "resource_\(resource)", binder: { view in
                view.bind(title: "full_info.subtitle_provider".localized)
            }, dynamicHeight: { _ in FullTransactionInfoTheme.sectionHeight })
            sections.append(Section(id: "resource_\(resource)", headerState: header, footerState: .marginColor(height: FullTransactionInfoTheme.sectionEmptyMargin, color: .clear), rows: [
                Row<SettingsCell>(id: "resource", height: FullTransactionInfoTheme.cellHeight, autoDeselect: true, bind: { cell, _ in
                    cell.bind(titleIcon: nil, title: resource, titleColor: FullTransactionInfoTheme.resourceTitleColor, showDisclosure: true, last: true)
                    cell.titleLabel.font = FullTransactionInfoTheme.resourceTitleFont
                }, action: { [weak self] cell in
                    self?.onTapResourceCell()
                })
            ]))
        }
        return sections
    }

    func onTap(item: FullTransactionItem) {
        delegate.onTap(item: item)
    }

    func onTapResourceCell() {
        delegate.onTapResourceCell()
    }

    @objc func onClose() {
        delegate.onClose()
    }

    func onRetry() {
        delegate.onRetryLoad()
    }

    @objc func onShare() {
    }

}


extension FullTransactionInfoViewController: IFullTransactionInfoView {

    func showLoading() {
        HudHelper.instance.showSpinner()
        shareButton.isEnabled = false
    }

    func hideLoading() {
        HudHelper.instance.hide()
        shareButton.isEnabled = true
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    func setProvider(name: String) {
        errorView?.set(title: "\(name)")
    }

    func reload() {
        tableView.reload()
    }

    func showError() {
        errorView?.set(hidden: false, animated: true)
    }

    func hideError() {
        errorView?.set(hidden: true, animated: false)
    }

}
