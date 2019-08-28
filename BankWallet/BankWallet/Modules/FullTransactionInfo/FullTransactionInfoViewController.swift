import UIKit
import SectionsTableView
import UIExtensions
import HUD
import SnapKit
import RxSwift

class FullTransactionInfoViewController: WalletViewController, SectionsDataSource {
    private let cellName = String(describing: FullTransactionInfoTextCell.self)
    private let closeButtonImage = UIImage(named: "Close Icon")
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))

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

        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        loadingView.set(hidden: true)

        if let errorView = errorView {
            view.addSubview(errorView)

            errorView.snp.makeConstraints { maker in
                maker.top.leading.equalToSuperview().offset(FullTransactionInfoTheme.errorViewMargin)
                maker.trailing.bottom.equalToSuperview().offset(-FullTransactionInfoTheme.errorViewMargin)
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

        if delegate.haveBlockExplorer {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.share".localized, style: .plain, target: self, action: #selector(onShare))
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    func showError(providerName: String?) {
        errorView?.set(title: providerName)
        errorView?.set(hidden: false, animated: true)
    }

    func hideError() {
        errorView?.set(hidden: true, animated: false)
    }

}
