import UIKit
import SnapKit
import ThemeKit
import SectionsTableView
import HUD
import RxSwift
import RxCocoa

class MarkdownViewController: ThemeViewController {
    private let viewModel: MarkdownViewModel
    private let showClose: Bool
    private let closeHandler: (() -> ())?
    private let handleRelativeUrl: Bool
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .large48)

    private var viewItems: [MarkdownBlockViewItem]?

    init(viewModel: MarkdownViewModel, showClose: Bool = false, closeHandler: (() -> ())? = nil, handleRelativeUrl: Bool) {
        self.viewModel = viewModel
        self.showClose = showClose
        self.closeHandler = closeHandler
        self.handleRelativeUrl = handleRelativeUrl

        super.init()

        hidesBottomBarWhenPushed = true
        navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if showClose {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: MarkdownHeader1Cell.self)
        tableView.registerCell(forClass: MarkdownHeader3Cell.self)
        tableView.registerCell(forClass: MarkdownTextCell.self)
        tableView.registerCell(forClass: MarkdownListItemCell.self)
        tableView.registerCell(forClass: MarkdownBlockQuoteCell.self)
        tableView.registerCell(forClass: MarkdownImageCell.self)
        tableView.registerCell(forClass: MarkdownImageTitleCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.sectionDataSource = self

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading

            if loading {
                self?.spinner.startAnimating()
            } else {
                self?.spinner.stopAnimating()
            }
        }

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems
            self?.tableView.reload()
        }

        subscribe(disposeBag, viewModel.openUrlSignal) { [weak self] url in
            let viewController = MarkdownModule.viewController(url: url)
            self?.navigationController?.pushViewController(viewController, animated: true)
        }

        tableView.buildSections()
    }

    @objc private func onClose() {
        dismiss(animated: true, completion: { [weak self] in
            self?.closeHandler?()
        })
    }

    private func headerRow(id: String, attributedString: NSAttributedString, level: Int) -> RowProtocol {
        if level == 1 || level == 2 {
            return header1Row(id: id, attributedString: attributedString)
        } else {
            return header3Row(id: id, attributedString: attributedString)
        }
    }

    private func header1Row(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<MarkdownHeader1Cell>(
                id: id,
                dynamicHeight: { containerWidth in
                    MarkdownHeader1Cell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func header3Row(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<MarkdownHeader3Cell>(
                id: id,
                dynamicHeight: { containerWidth in
                    MarkdownHeader3Cell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func textRow(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<MarkdownTextCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    MarkdownTextCell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { [weak self] cell, _ in
                    cell.bind(attributedString: attributedString, delegate: self)
                }
        )
    }

    private func listItemRow(id: String, attributedString: NSAttributedString, prefix: String?, tightTop: Bool, tightBottom: Bool) -> RowProtocol {
        Row<MarkdownListItemCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    MarkdownListItemCell.height(containerWidth: containerWidth, attributedString: attributedString, tightTop: tightTop, tightBottom: tightBottom)
                },
                bind: { [weak self] cell, _ in
                    cell.bind(attributedString: attributedString, delegate: self, prefix: prefix, tightTop: tightTop, tightBottom: tightBottom)
                }
        )
    }

    private func blockQuoteRow(id: String, attributedString: NSAttributedString, tightTop: Bool, tightBottom: Bool) -> RowProtocol {
        Row<MarkdownBlockQuoteCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    MarkdownBlockQuoteCell.height(containerWidth: containerWidth, attributedString: attributedString, tightTop: tightTop, tightBottom: tightBottom)
                },
                bind: { [weak self] cell, _ in
                    cell.bind(attributedString: attributedString, delegate: self, tightTop: tightTop, tightBottom: tightBottom)
                }
        )
    }

    private func imageRow(id: String, url: URL, type: MarkdownImageType, tight: Bool) -> RowProtocol {
        Row<MarkdownImageCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    MarkdownImageCell.height(containerWidth: containerWidth, type: type, tight: tight)
                },
                bind: { cell, _ in
                    cell.bind(imageUrl: url, type: type, tight: tight)
                }
        )
    }

    private func imageTitleRow(id: String, text: String) -> RowProtocol {
        Row<MarkdownImageTitleCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    MarkdownImageTitleCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private func row(index: Int, viewItem: MarkdownBlockViewItem) -> RowProtocol {
        switch viewItem {
        case let .header(attributedString, level):
            return headerRow(
                    id: "header_\(index)",
                    attributedString: attributedString,
                    level: level
            )
        case let .text(attributedString):
            return textRow(
                    id: "text_\(index)",
                    attributedString: attributedString
            )
        case let .listItem(attributedString, prefix, tightTop, tightBottom):
            return listItemRow(
                    id: "listItem_\(index)",
                    attributedString: attributedString,
                    prefix: prefix,
                    tightTop: tightTop,
                    tightBottom: tightBottom
            )
        case let .blockQuote(attributedString, tightTop, tightBottom):
            return blockQuoteRow(
                    id: "blockQuote_\(index)",
                    attributedString: attributedString,
                    tightTop: tightTop,
                    tightBottom: tightBottom
            )
        case let .image(url, type, tight):
            return imageRow(
                    id: "image_\(index)",
                    url: url,
                    type: type,
                    tight: tight
            )
        case let .imageTitle(text):
            return imageTitleRow(
                    id: "imageTitle_\(index)",
                    text: text
            )
        }
    }

}

extension MarkdownViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        guard let viewItems = viewItems else {
            return []
        }

        return [
            Section(
                    id: "blocks",
                    rows: viewItems.enumerated().map { row(index: $0, viewItem: $1) }
            ),
            Section(
                    id: "brand",
                    headerState: .margin(height: .margin32),
                    rows: [
                        Row<BrandFooterCell>(
                                id: "brand",
                                dynamicHeight: { containerWidth in
                                    BrandFooterCell.height(containerWidth: containerWidth, title: BrandFooterCell.brandText)
                                },
                                bind: { cell, _ in
                                    cell.title = BrandFooterCell.brandText
                                }
                        )
                    ]
            )
        ]
    }

}

extension MarkdownViewController: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard handleRelativeUrl, URL.pathExtension == "md" else {
            return true
        }

        viewModel.onTap(url: URL)

        return false
    }

}
