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

    init(image: BottomSheetTitleView.Image?, title: String, subtitle: String?, items: [BottomSheetModule.Item], buttons: [BottomSheetModule.Button]) {
        self.items = items
        self.buttons = buttons

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
        }

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
            component.button.set(style: button.style)
            component.button.setTitle(button.title, for: .normal)
            component.onTap = { [weak self] in
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

        tableView.sectionDataSource = self

        tableView.buildSections()
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

    private func highlightedDescriptionSection(index: Int, text: String) -> SectionProtocol {
        Section(
                id: "section-\(index)",
                rows: [
                    tableView.highlightedDescriptionRow(
                            id: "description_\(index)",
                            text: text,
                            ignoreBottomMargin: true
                    )
                ]
        )
    }

}

extension BottomSheetViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        items.enumerated().map { index, item in
            switch item {
            case .description(let text): return descriptionSection(index: index, text: text)
            case .highlightedDescription(let text): return highlightedDescriptionSection(index: index, text: text)
            }
        }
    }

}
