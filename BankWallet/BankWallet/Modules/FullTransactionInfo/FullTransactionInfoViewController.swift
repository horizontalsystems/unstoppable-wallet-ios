import UIKit
import SectionsTableView
import UIExtensions
import HUD
import SnapKit
import RxSwift
import ThemeKit

class FullTransactionInfoViewController: ThemeViewController, SectionsDataSource {
    static let spinnerLineWidth: CGFloat = 4
    static let spinnerSideSize: CGFloat = 32

    private let cellName = String(describing: FullTransactionInfoTextCell.self)
    private let closeButtonImage = UIImage(named: "Close Icon")
    private let shareButtonImage = UIImage(named: "Share Full Transaction Icon")
    private let attentionImage = UIImage(named: "Attention Icon Large", in: Bundle(for: RequestErrorView.self), compatibleWith: nil)?.tinted(with: .themeGray)
    private let errorImage =  UIImage(named: "Error Icon", in: Bundle(for: RequestErrorView.self), compatibleWith: nil)?.tinted(with: .themeGray)

    private let delegate: IFullTransactionInfoViewDelegate

    let tableView = SectionsTableView(style: .plain)
    private var headerBackgroundTriggerOffset: CGFloat?
    private weak var hashHeaderView: FullTransactionHashHeaderView?

    private let closeButton = UIButton(frame: .zero)
    private let errorView = RequestErrorView()
    private let loadingView = HUDProgressView(strokeLineWidth: FullTransactionInfoViewController.spinnerLineWidth,
            radius: FullTransactionInfoViewController.spinnerSideSize / 2 - FullTransactionInfoViewController.spinnerLineWidth / 2,
            strokeColor: .themeGray)

    init(delegate: IFullTransactionInfoViewDelegate) {
        self.delegate = delegate
        super.init()
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
        tableView.registerCell(forClass: RightLabelCell.self)
        tableView.registerCell(forClass: FullTransactionHeaderCell.self)
        tableView.registerHeaderFooter(forClass: FullTransactionHashHeaderView.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none

        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        loadingView.set(hidden: true)

        view.addSubview(errorView)

        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin6x)
        }
        errorView.set(hidden: true)

        delegate.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        headerBackgroundTriggerOffset = headerBackgroundTriggerOffset == nil ? tableView.contentOffset.y : headerBackgroundTriggerOffset
    }

    func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        let hash = delegate.transactionHash
        let hashHeader: ViewState<FullTransactionHashHeaderView> = .cellType(hash: "section_\(hash)", binder: { [weak self] view in
            self?.hashHeaderView = view
            view.bind(value: hash, onTap: {
                self?.onTapHash()
            })
        }, dynamicHeight: { _ in 56 })

        if let providerName = delegate.providerName {
            rows.append(
                Row<FullTransactionInfoTextCell>(id: "resource", height: .heightSingleLineCell, autoDeselect: true, bind: { cell, _ in
                    let item = FullTransactionItem(title: "full_info.source.title".localized, value: providerName)
                    cell.bind(item: item, selectionStyle: .default, showDisclosure: true, last: true)
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
                        Row<FullTransactionHeaderCell>(id: "header_\(title)", height: 44, bind: { cell, _ in
                            cell.bind(title: title)
                        })
                )
            } else {
                rows.append(Row<FullTransactionHeaderCell>(id: "header_\(sectionIndex)", height: .margin8x))
            }
            for (rowIndex, item) in section.items.enumerated() {
                rows.append(
                        Row<FullTransactionInfoTextCell>(id: "section_\(sectionIndex)_row_\(rowIndex)", height: .heightSingleLineCell, bind: { [weak self] cell, _ in
                    cell.bind(item: item, last: rowIndex == section.items.count - 1, onTap: item.clickable ? {
                        self?.onTap(item: item)
                    } : nil)
                }))
            }
        }

        if let providerName = delegate.providerName, delegate.haveBlockExplorer {
            rows.append(Row<FullTransactionHeaderCell>(id: "provider_header", height: .margin8x))
            rows.append(
                    Row<FullTransactionProviderLinkCell>(id: "link_cell", height: 20, bind: { [weak self] cell, _ in
                    cell.bind(text: providerName) {
                        self?.onTapProviderLink()
                    }
                })
            )
        }

        return [Section(id: "section", headerState: hashHeader, footerState: .marginColor(height: .margin8x, color: .clear), rows: rows)]
    }

    func didScroll() {
        if let headerBackgroundTriggerOffset = headerBackgroundTriggerOffset {
            hashHeaderView?.backgroundView?.backgroundColor = tableView.contentOffset.y > headerBackgroundTriggerOffset ? .themeNavigationBarBackground : .clear
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
    }

    func hideLoading() {
        self.loadingView.set(hidden: true)
        loadingView.stopAnimating()
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

    func showOffline(providerName: String?) {
        errorView.bind(image: errorImage, title: "full_info.error.server_offline".localized, buttonText: "full_info.error.retry".localized, linkText: "full_info.error.change_source".localized, onTapButton: onRetry, onTapLink: onTapChangeResource)
        errorView.set(hidden: false, animated: true)
    }

    func showError(providerName: String?) {
        errorView.bind(image: attentionImage, title: "full_info.error.transaction_not_found".localized, linkText: "full_info.error.change_source".localized, onTapLink: onTapChangeResource)
        errorView.set(hidden: false, animated: true)
    }

    func hideError() {
        errorView.set(hidden: true, animated: false)
    }

}
