import UIKit
import ThemeKit
import ActionSheet
import ComponentKit
import SectionsTableView

class BottomSheetViewController: ThemeActionSheetController {
    private let items: [BottomSheetModule.Item]
    private let buttons: [BottomSheetModule.Button]

    private var titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let buttonStackView = UIStackView()

    private weak var delegate: IBottomSheetDismissDelegate?
    private var didTapAnyButton = false

    init(image: BottomSheetTitleView.Image?, title: String, subtitle: String?, items: [BottomSheetModule.Item], buttons: [BottomSheetModule.Button], delegate: IBottomSheetDismissDelegate? = nil) {
        self.items = items
        self.buttons = buttons
        self.delegate = delegate

        super.init()

        titleView.bind(image: image, title: title, subtitle: subtitle, viewController: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(titleView.snp.bottom)
            maker.leading.trailing.equalToSuperview()

            if buttons.isEmpty {
                maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
            }
        }

        if !buttons.isEmpty {
            view.addSubview(buttonStackView)
            buttonStackView.snp.makeConstraints { maker in
                maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
                maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
            }

            buttonStackView.axis = .vertical
            buttonStackView.alignment = .fill
            buttonStackView.spacing = .margin12

            for button in buttons {
                let component = PrimaryButtonComponent()
                var accessory = PrimaryButton.AccessoryType.none
                if let imageName = button.imageName {
                    accessory = .icon(image: UIImage(named: imageName))
                }
                component.button.set(style: button.style, accessoryType: accessory)
                component.button.setTitle(button.title, for: .normal)

                component.onTap = { [weak self] in
                    self?.didTapAnyButton = true
                    switch button.actionType {
                    case .regular:
                        button.action?()
                        self?.dismiss(animated: true)
                    case .afterClose:
                        self?.dismiss(animated: true) {
                            button.action?()
                        }
                    }
                }

                component.snp.makeConstraints { make in
                    make.height.equalTo(PrimaryButton.height)
                }

                buttonStackView.addArrangedSubview(component)
            }
        }

        tableView.sectionDataSource = self

        tableView.buildSections()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !didTapAnyButton {
            delegate?.bottomSelectorOnDismiss()
        }
    }


    private func descriptionSection(index: Int, text: String) -> SectionProtocol {
        Section(
                id: "section-\(index)",
                rows: [
                    tableView.descriptionRow(
                            id: "description_\(index)",
                            text: text,
                            ignoreBottomMargin: true
                    )
                ]
        )
    }

    private func highlightedDescriptionSection(index: Int, style: HighlightedDescriptionBaseView.Style = .yellow, text: String) -> SectionProtocol {
        Section(
                id: "section-\(index)",
                rows: [
                    tableView.highlightedDescriptionRow(
                            id: "description_\(index)",
                            style: style,
                            text: text,
                            ignoreBottomMargin: true
                    )
                ]
        )
    }

    private func copyableValueSection(index: Int, title: String, value: String) -> SectionProtocol {
        Section(
                id: "section-\(index)",
                headerState: .margin(height: .margin12),
                rows: [
                    CellBuilderNew.row(
                            rootElement: .hStack([
                                .textElement(text: .body(title)),
                                .secondaryButton { component in
                                    component.button.set(style: .default)
                                    component.button.setTitle(value, for: .normal)
                                    component.onTap = {
                                        CopyHelper.copyAndNotify(value: value)
                                    }
                                }
                            ]),
                            tableView: tableView,
                            id: "copyable-value-\(index)",
                            height: .heightCell48,
                            bind: { cell in
                                cell.set(backgroundStyle: .bordered, isFirst: true, isLast: true)
                            }
                    )
                ]
        )
    }

    private func contractAddressSection(index: Int, imageUrl: String, value: String, explorerUrl: String?) -> SectionProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .bordered
        let textFont: UIFont = .subhead1

        return Section(
                id: "section-\(index)",
                headerState: tableView.sectionHeader(text: "manage_wallets.contract_address".localized, height: 41),
                rows: [
                    CellBuilderNew.row(
                            rootElement: .hStack([
                                .imageElement(image: .url(imageUrl, placeholder: "placeholder_rectangle_32"), size: .image32),
                                .text { component in
                                    component.font = textFont
                                    component.textColor = .themeLeah
                                    component.text = value
                                    component.numberOfLines = 0
                                },
                                .secondaryCircleButton { [weak self] component in
                                    if let explorerUrl = explorerUrl {
                                        component.isHidden = false
                                        component.button.set(image: UIImage(named: "globe_20"))
                                        component.onTap = { self?.open(url: explorerUrl) }
                                    } else {
                                        component.isHidden = true
                                    }
                                }
                            ]),
                            tableView: tableView,
                            id: "copyable-value-\(index)",
                            dynamicHeight: { width in
                                let height = CellBuilderNew.height(
                                        containerWidth: width,
                                        backgroundStyle: backgroundStyle,
                                        text: value,
                                        font: textFont,
                                        verticalPadding: .margin12,
                                        elements: explorerUrl != nil ? [.fixed(width: .iconSize32), .multiline, .fixed(width: SecondaryCircleButton.size)] : [.fixed(width: .iconSize32), .multiline]
                                )

                                return max(height, .heightCell56)
                            },
                            bind: { cell in
                                cell.set(backgroundStyle: backgroundStyle, isFirst: true, isLast: true)
                            }
                    )
                ]
        )
    }

    private func open(url: String) {
        UrlManager(inApp: true).open(url: url, from: self)
    }

}

extension BottomSheetViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        items.enumerated().map { index, item in
            switch item {
            case .description(let text): return descriptionSection(index: index, text: text)
            case let .highlightedDescription(text, style): return highlightedDescriptionSection(index: index, style: style, text: text)
            case let .copyableValue(title, value): return copyableValueSection(index: index, title: title, value: value)
            case let .contractAddress(imageUrl, value, explorerUrl): return contractAddressSection(index: index, imageUrl: imageUrl, value: value, explorerUrl: explorerUrl)
            }
        }
    }

}
