import UIKit
import SectionsTableViewKit
import GrouviExtensions
import GrouviHUD
import SnapKit
import RxSwift

class FullTransactionInfoViewController: UIViewController, SectionsDataSource {
    private let cellName = String(describing: FullTransactionInfoTextCell.self)
    private let closeButtonImage = UIImage(named: "Close Full Transaction Icon")
    private let shareButtonImage = UIImage(named: "Share Full Transaction Icon")

    private let delegate: IFullTransactionInfoViewDelegate

    let tableView = SectionsTableView(style: .grouped)

    private let closeButton = UIButton(frame: .zero)
    private let shareButton = UIButton(frame: .zero)

    private var errorView: RequestErrorView?
    private let loadingView = HUDProgressView(strokeLineWidth: FullTransactionInfoTheme.spinnerLineWidth, radius: FullTransactionInfoTheme.spinnerSideSize / 2 - FullTransactionInfoTheme.spinnerLineWidth / 2, strokeColor: UIColor.cryptoGray)

    init(delegate: IFullTransactionInfoViewDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)

        errorView = RequestErrorView(subtitle: "full_info.error.subtitle".localized, buttonText: "full_info.error.retry".localized, linkText: "full_info.error.change_source".localized, onTapButton: { [weak self] in
            self?.onRetry()
        }, onTapLink: { [weak self] in
            self?.onTapChangeResource()
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.controllerBackground

        title = "full_info.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.backgroundColor = .clear

        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: FullTransactionInfoTextCell.self)
        tableView.registerCell(forClass: FullTransactionProviderLinkCell.self)
        tableView.registerCell(forClass: SettingsRightLabelCell.self)
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
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.bottom.equalTo(toolbar.snp.top)
        }
        loadingView.set(hidden: true)
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

        if let providerName = delegate.providerName {
            sections.append(Section(id: "resource_\(providerName)", headerState: .marginColor(height: FullTransactionInfoTheme.sectionEmptyMargin, color: .clear), rows: [
                Row<SettingsRightLabelCell>(id: "resource", height: FullTransactionInfoTheme.cellHeight, autoDeselect: true, bind: { cell, _ in
                    cell.bind(titleIcon: nil, title: "full_info.source.title".localized, rightText: providerName, showDisclosure: true, last: true)
                    cell.titleLabel.font = FullTransactionInfoTheme.resourceTitleFont
                }, action: { [weak self] cell in
                    self?.onTapChangeResource()
                })
            ]))
        }

        for sectionIndex in 0..<delegate.numberOfSections() {
            var sectionRows = [RowProtocol]()
            guard let section = delegate.section(sectionIndex) else {
                continue
            }
            for (rowIndex, item) in section.items.enumerated() {
                sectionRows.append(Row<FullTransactionInfoTextCell>(id: "section_\(sectionIndex)_row_\(rowIndex)", height: FullTransactionInfoTheme.cellHeight, bind: { [weak self] cell, _ in
                    cell.separatorView.backgroundColor = FullTransactionInfoTheme.separatorColor

                    cell.bind(item: item, last: rowIndex == section.items.count - 1, onTap: item.clickable ? {
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

        if let providerName = delegate.providerName {
            sections.append(Section(id: "link_provider", headerState: .marginColor(height: FullTransactionInfoTheme.sectionEmptyMargin, color: .clear), footerState: .margin(height: FullTransactionInfoTheme.linkCellBottomMargin), rows: [
                Row<FullTransactionProviderLinkCell>(id: "link_cell", height: FullTransactionInfoTheme.linkCellHeight, bind: { [weak self] cell, _ in
                    cell.bind(text: providerName) {
                        self?.onTapProviderLink()
                    }
                })
            ]))
        }
        return sections
    }

    func onTap(item: FullTransactionItem) {
        delegate.onTap(item: item)
    }

    func onTapChangeResource() {
        delegate.onTapChangeResource()
    }

    func onTapProviderLink() {
        delegate.onTapProviderLink()
    }

    @objc func onClose() {
        delegate.onClose()
    }

    func onRetry() {
        delegate.onRetryLoad()
    }

    @objc func onShare() {
        delegate.onShare()
    }
}


extension FullTransactionInfoViewController: IFullTransactionInfoView {

    func showLoading() {
        loadingView.set(hidden: false)
        loadingView.startAnimating()

        shareButton.isEnabled = false
    }

    func hideLoading() {
        self.loadingView.set(hidden: true)
        loadingView.stopAnimating()
        shareButton.isEnabled = true
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    func reload() {
        tableView.reload()
    }

    func showError(providerName: String?) {
        errorView?.set(title: providerName)
        errorView?.set(hidden: false, animated: true)
    }

    func hideError() {
        errorView?.set(hidden: true, animated: false)
    }

}
