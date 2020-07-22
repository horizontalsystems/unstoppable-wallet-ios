import UIKit
import SnapKit
import ThemeKit
import SectionsTableView
import HUD

class GuideViewController: ThemeViewController {
    private static let spinnerRadius: CGFloat = 8
    private static let spinnerLineWidth: CGFloat = 2

    private let delegate: IGuideViewDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDProgressView(
            strokeLineWidth: GuideViewController.spinnerLineWidth,
            radius: GuideViewController.spinnerRadius,
            strokeColor: .themeGray
    )

    private var viewItems = [GuideBlockViewItem]()

    init(delegate: IGuideViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
        navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Attention Icon")?.tinted(with: .themeJacob), style: .plain, target: self, action: #selector(onTapFontSizeButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: GuideHeader1Cell.self)
        tableView.registerCell(forClass: GuideHeader3Cell.self)
        tableView.registerCell(forClass: GuideTextCell.self)
        tableView.registerCell(forClass: GuideListItemCell.self)
        tableView.registerCell(forClass: GuideBlockQuoteCell.self)
        tableView.registerCell(forClass: GuideImageCell.self)
        tableView.registerCell(forClass: GuideImageTitleCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.sectionDataSource = self

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(GuideViewController.spinnerRadius * 2 + GuideViewController.spinnerLineWidth)
        }

        delegate.onLoad()

        tableView.buildSections()
    }

    @objc private func onTapFontSizeButton() {
        delegate.onTapFontSize()
    }

    private func headerRow(id: String, attributedString: NSAttributedString, level: Int) -> RowProtocol {
        if level == 1 || level == 2 {
            return header1Row(id: id, attributedString: attributedString)
        } else {
            return header3Row(id: id, attributedString: attributedString)
        }
    }

    private func header1Row(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideHeader1Cell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideHeader1Cell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func header3Row(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideHeader3Cell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideHeader3Cell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func textRow(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideTextCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideTextCell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { [weak self] cell, _ in
                    cell.bind(attributedString: attributedString, delegate: self)
                }
        )
    }

    private func listItemRow(id: String, attributedString: NSAttributedString, prefix: String?, tightTop: Bool, tightBottom: Bool) -> RowProtocol {
        Row<GuideListItemCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideListItemCell.height(containerWidth: containerWidth, attributedString: attributedString, tightTop: tightTop, tightBottom: tightBottom)
                },
                bind: { [weak self] cell, _ in
                    cell.bind(attributedString: attributedString, delegate: self, prefix: prefix, tightTop: tightTop, tightBottom: tightBottom)
                }
        )
    }

    private func blockQuoteRow(id: String, attributedString: NSAttributedString, tightTop: Bool, tightBottom: Bool) -> RowProtocol {
        Row<GuideBlockQuoteCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideBlockQuoteCell.height(containerWidth: containerWidth, attributedString: attributedString, tightTop: tightTop, tightBottom: tightBottom)
                },
                bind: { [weak self] cell, _ in
                    cell.bind(attributedString: attributedString, delegate: self, tightTop: tightTop, tightBottom: tightBottom)
                }
        )
    }

    private func imageRow(id: String, url: URL, type: GuideImageType, tight: Bool) -> RowProtocol {
        Row<GuideImageCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideImageCell.height(containerWidth: containerWidth, type: type, tight: tight)
                },
                bind: { cell, _ in
                    cell.bind(imageUrl: url, type: type, tight: tight)
                }
        )
    }

    private func imageTitleRow(id: String, text: String) -> RowProtocol {
        Row<GuideImageTitleCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideImageTitleCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private func row(index: Int, viewItem: GuideBlockViewItem) -> RowProtocol {
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

extension GuideViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "blocks",
                    rows: viewItems.enumerated().map { row(index: $0, viewItem: $1) }
            ),
            Section(
                    id: "footer",
                    rows: [
                        Row<BrandFooterCell>(
                                id: "footer",
                                dynamicHeight: { containerWidth in
                                    BrandFooterCell.height(containerWidth: containerWidth)
                                }
                        )
                    ]
            )
        ]
    }

}

extension GuideViewController: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard URL.pathExtension == "md" else {
            return true
        }

        delegate.onTapGuide(url: URL)

        return false
    }

}

extension GuideViewController: IGuideView {

    func set(viewItems: [GuideBlockViewItem]) {
        self.viewItems = viewItems
    }

    func refresh() {
        tableView.reload()
    }

    func setSpinner(visible: Bool) {
        tableView.isHidden = visible
        spinner.isHidden = !visible

        if visible {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

}
