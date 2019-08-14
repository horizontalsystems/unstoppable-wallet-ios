import UIKit
import SectionsTableView
import UIExtensions
import HUD
import SnapKit
import RxSwift

class FullTransactionInfoViewController: WalletViewController, SectionsDataSource {
    private let cellName = String(describing: FullTransactionInfoTextCell.self)
    private let closeButtonImage = UIImage(named: "Close Full Transaction Icon")
    private let shareButtonImage = UIImage(named: "Share Full Transaction Icon")

    private let delegate: IFullTransactionInfoViewDelegate

    let tableView = SectionsTableView(style: .plain)
    private var headerBackgroundTriggerOffset: CGFloat?
    private weak var hashHeaderView: FullTransactionHashHeaderView?

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
        tableView.registerCell(forClass: FullTransactionHeaderCell.self)
        tableView.registerHeaderFooter(forClass: FullTransactionHashHeaderView.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = .clear
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: FullTransactionInfoTheme.bottomBarHeight))

        let holderView = UIView()
        holderView.backgroundColor = AppTheme.navigationBarBackgroundColor
        view.addSubview(holderView)
        holderView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
        }
        let holderSeparator = UIView()
        holderSeparator.backgroundColor = AppTheme.separatorColor
        holderView.addSubview(holderSeparator)
        holderSeparator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
        let toolbar = UIView(frame: .zero)
        holderView.addSubview(toolbar)

        toolbar.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview()
            maker.bottom.equalTo(holderView.safeAreaLayoutGuide)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        headerBackgroundTriggerOffset = headerBackgroundTriggerOffset == nil ? tableView.contentOffset.y : headerBackgroundTriggerOffset
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        let hash = delegate.transactionHash
        let hashHeader: ViewState<FullTransactionHashHeaderView> = .cellType(hash: "section_\(hash)", binder: { [weak self] view in
            self?.hashHeaderView = view
            view.bind(value: hash, onTap: {
                self?.onTapHash()
            })
        }, dynamicHeight: { _ in FullTransactionInfoTheme.hashHeaderHeight })

        if let providerName = delegate.providerName {
            rows.append(
                Row<FullTransactionInfoTextCell>(id: "resource", height: FullTransactionInfoTheme.cellHeight, autoDeselect: true, bind: { cell, _ in
                    let item = FullTransactionItem(title: "full_info.source.title".localized, value: providerName)
                    cell.bind(item: item, selectionStyle: .default, showDisclosure: true, last: true, showTopSeparator: true)
                }, action: { [weak self] cell in
                    self?.onTapChangeResource()
                })
            )
        }

        for sectionIndex in 0..<delegate.numberOfSections() {
            guard let section = delegate.section(sectionIndex) else {
                continue
            }
            if let title = section.title {
                rows.append(
                        Row<FullTransactionHeaderCell>(id: "header_\(title)", height: FullTransactionInfoTheme.sectionHeight, bind: { cell, _ in
                            cell.bind(title: title)
                        })
                )
            } else {
                rows.append(Row<FullTransactionHeaderCell>(id: "header_\(sectionIndex)", height: FullTransactionInfoTheme.sectionEmptyMargin))
            }
            for (rowIndex, item) in section.items.enumerated() {
                rows.append(
                        Row<FullTransactionInfoTextCell>(id: "section_\(sectionIndex)_row_\(rowIndex)", height: FullTransactionInfoTheme.cellHeight, bind: { [weak self] cell, _ in
                    cell.bind(item: item, last: rowIndex == section.items.count - 1, onTap: item.clickable ? {
                        self?.onTap(item: item)
                    } : nil)
                }))
            }
        }

        if let providerName = delegate.providerName, delegate.haveBlockExplorer {
            rows.append(Row<FullTransactionHeaderCell>(id: "provider_header", height: FullTransactionInfoTheme.sectionEmptyMargin, bind: { view, _ in
                view.bind(showBottomSeparator: false)
            }))
            rows.append(
                    Row<FullTransactionProviderLinkCell>(id: "link_cell", height: FullTransactionInfoTheme.linkCellHeight, bind: { [weak self] cell, _ in
                    cell.bind(text: providerName) {
                        self?.onTapProviderLink()
                    }
                })
            )
        }

        return [Section(id: "section", headerState: hashHeader, footerState: .marginColor(height: FullTransactionInfoTheme.sectionEmptyMargin, color: .clear), rows: rows)]
    }

    func didScroll() {
        if let headerBackgroundTriggerOffset = headerBackgroundTriggerOffset {
            hashHeaderView?.backgroundView?.backgroundColor = tableView.contentOffset.y > headerBackgroundTriggerOffset ? AppTheme.navigationBarBackgroundColor : .clear
        }
    }

    func onTap(item: FullTransactionItem) {
        delegate.onTap(item: item)
    }

    func onTapHash() {
        delegate.onTapHash()
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
