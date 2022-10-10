import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import EvmKit
import Kingfisher
import UIExtensions
import ComponentKit

class SendEip721ViewController: KeyboardAwareViewController {
    private let wrapperViewHeight: CGFloat = .heightButton + .margin32 + .margin16

    private let evmKitWrapper: EvmKitWrapper
    private let viewModel: SendEip721ViewModel
    private let disposeBag = DisposeBag()

    private let iconImageView = UIImageView()
    private let tableView = SectionsTableView(style: .grouped)

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let gradientWrapperView = GradientView(gradientHeight: .margin16, fromColor: UIColor.themeTyler.withAlphaComponent(0), toColor: UIColor.themeTyler)
    private let nextButton = PrimaryButton()

    private var isLoaded = false

    init(evmKitWrapper: EvmKitWrapper, viewModel: SendEip721ViewModel, recipientViewModel: RecipientAddressViewModel) {
        self.evmKitWrapper = evmKitWrapper
        self.viewModel = viewModel

        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "send.send".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .done, target: self, action: #selector(onTapNext))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.sectionDataSource = self

        tableView.registerCell(forClass: NftAssetImageCell.self)

        recipientCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        recipientCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        recipientCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        view.addSubview(gradientWrapperView)
        gradientWrapperView.snp.makeConstraints { maker in
            maker.height.equalTo(wrapperViewHeight).priority(.high)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        gradientWrapperView.addSubview(nextButton)
        nextButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }
        nextButton.set(style: .yellow)
        nextButton.setTitle("button.next".localized, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

        subscribe(disposeBag, viewModel.proceedEnableDriver) { [weak self] in
            self?.nextButton.isEnabled = $0
            self?.navigationItem.rightBarButtonItem?.isEnabled = $0
        }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] in self?.openConfirm(sendData: $0) }

        setInitialState(bottomPadding: wrapperViewHeight)
        tableView.buildSections()
        isLoaded = true
    }

    @objc private func onTapNext() {
        viewModel.didTapProceed()
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    private func openConfirm(sendData: SendEvmData) {
        guard let viewController = SendEvmConfirmationModule.viewController(evmKitWrapper: evmKitWrapper, sendData: sendData) else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension SendEip721ViewController: SectionsDataSource {

    private func imageSection(nftImage: NftImage) -> SectionProtocol {
        Section(
                id: "image",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [
                    Row<NftAssetImageCell>(
                            id: "image",
                            dynamicHeight: { width in
                                NftAssetImageCell.height(containerWidth: width, maxHeight: 120, ratio: nftImage.ratio)
                            },
                            bind: { cell, _ in
                                cell.bind(nftImage: nftImage, cornerRadius: .cornerRadius8)
                            }
                    )
                ]
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let nftImage = viewModel.nftImage {
            sections.append(imageSection(nftImage: nftImage))
        }

        let nameFont: UIFont = .headline1
        let name = viewModel.name

        sections.append(
                Section(
                        id: "title",
                        rows: [
                            CellBuilderNew.row(
                                    rootElement: .text { component in
                                        component.font = nameFont
                                        component.textColor = .themeLeah
                                        component.text = name
                                        component.numberOfLines = 0
                                        component.textAlignment = .center
                                    },
                                    tableView: tableView,
                                    id: "name",
                                    dynamicHeight: { width in
                                        CellBuilderNew.height(
                                                containerWidth: width,
                                                backgroundStyle: .transparent,
                                                text: name,
                                                font: nameFont,
                                                verticalPadding: .margin12,
                                                elements: [.multiline]
                                        )
                                    },
                                    bind: { cell in
                                        cell.set(backgroundStyle: .transparent, isFirst: true)
                                    }
                            )
                        ]
                )
        )

        sections.append(
                Section(
                        id: "recipient",
                        headerState: .margin(height: .margin12),
                        footerState: .margin(height: .margin32),
                        rows: [
                            StaticRow(
                                    cell: recipientCell,
                                    id: "recipient-input",
                                    dynamicHeight: { [weak self] width in
                                        self?.recipientCell.height(containerWidth: width) ?? 0
                                    }
                            ),
                            StaticRow(
                                    cell: recipientCautionCell,
                                    id: "recipient-caution",
                                    dynamicHeight: { [weak self] width in
                                        self?.recipientCautionCell.height(containerWidth: width) ?? 0
                                    }
                            )
                        ]
                )
        )

        return sections
    }

}
