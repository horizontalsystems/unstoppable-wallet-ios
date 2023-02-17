import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

protocol IFeeViewModelNew {
    var showInfoIcon: Bool { get }
    var valueDriver: Driver<FeeCellNew.Value?> { get }
    var spinnerVisibleDriver: Driver<Bool> { get }
}

class FeeCellNew: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()

    private let viewModel: IFeeViewModelNew

    private var value: FeeCellNew.Value?
    private var spinnerVisible: Bool = false

    init(viewModel: IFeeViewModelNew) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true
        set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        selectionStyle = viewModel.showInfoIcon ? .default : .none
        sync()

        subscribe(disposeBag, viewModel.valueDriver) { [weak self] value in
            self?.value = value
            self?.sync()
        }
        subscribe(disposeBag, viewModel.spinnerVisibleDriver) { [weak self] visible in
            self?.spinnerVisible = visible
            self?.sync()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync() {
        let titleElements: [CellBuilderNew.CellElement] = [
            .textElement(text: .subhead2("fee_settings.max_fee".localized), parameters: .highHugging)
        ]

        var infoElements = [CellBuilderNew.CellElement]()
        if viewModel.showInfoIcon {
            infoElements.append(contentsOf: [
                .margin8,
                .imageElement(image: .local(UIImage(named: "circle_information_20")?.withTintColor(.themeGray)), size: .image20),
                .margin0,
                .text { _ in },
            ])
        }

        let valueElements: [CellBuilderNew.CellElement] = [
            .vStackCentered([
                .text({ [weak self] component in
                    if let value = self?.value, case let .regular(text, _) = value {
                        component.font = .subhead1
                        component.textColor = .themeLeah
                        component.text = text
                        component.textAlignment = .right
                    }
                }),
                .margin(1),
                .text({ [weak self] component in
                    if let value = self?.value, case let .regular(_, secondaryText) = value {
                        component.font = .caption
                        component.textColor = .themeGray
                        component.text = secondaryText ?? "---"
                        component.textAlignment = .right
                    }
                }),
            ], { [weak self] component in
                if let value = self?.value, case .regular = value {
                    component.isHidden = false
                } else {
                    component.isHidden = true
                }
            }),
            .text({ [weak self] component in
                if let value = self?.value, case let .error(text) = value {
                    component.isHidden = false
                    component.font = .subhead1
                    component.textColor = .themeLucian
                    component.text = text
                    component.textAlignment = .right
                } else {
                    component.isHidden = true
                }
            }),
            .spinner20 { [weak self] component in
                component.isHidden = !(self?.spinnerVisible ?? false)
            }
        ]

        CellBuilderNew.buildStatic(cell: self, rootElement: .hStack(titleElements + infoElements + valueElements))
    }

}

extension FeeCellNew {

    enum Value {
        case disabled(text: String)
        case regular(text: String, secondaryText: String?)
        case error(text: String)

        var textColor: UIColor {
            switch self {
            case .disabled: return .themeGray
            case .regular: return .themeLeah
            case .error: return .themeLucian
            }
        }
    }

}
