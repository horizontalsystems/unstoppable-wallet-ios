import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

protocol IFeeViewModel {
    var hasInformation: Bool { get }
    var title: String { get }
    var valueDriver: Driver<FeeCell.Value?> { get }
    var spinnerVisibleDriver: Driver<Bool> { get }
}

extension IFeeViewModel {

    var hasInformation: Bool {
        true
    }

    var title: String {
        "fee_settings.max_fee".localized
    }

}

class FeeCell: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()

    private let viewModel: IFeeViewModel

    private var value: FeeCell.Value?
    private var spinnerVisible: Bool = false

    init(viewModel: IFeeViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true
        set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        selectionStyle = viewModel.hasInformation ? .default : .none
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
        CellBuilderNew.buildStatic(cell: self, rootElement:
            .hStack([
                .image24 { [weak self] (component: ImageComponent) in
                    component.imageView.image = UIImage(named: "circle_information_24")
                    component.isHidden = !(self?.viewModel.hasInformation ?? false)
                },
                .text { [weak self] (component: TextComponent) -> () in
                    component.font = .subhead2
                    component.textColor = .themeGray
                    component.text = self?.viewModel.title
                },
                .text { [weak self] (component: TextComponent) -> () in
                    if let value = self?.value {
                        component.isHidden = false
                        component.font = .subhead1
                        component.textColor = value.type.textColor
                        component.text = value.text
                    } else {
                        component.isHidden = true
                    }
                },
                .spinner20 { [weak self] (component: SpinnerComponent) -> () in
                    component.isHidden = !(self?.spinnerVisible ?? false)
                }
            ])
        )
    }

}

extension FeeCell {

    enum ValueType {
        case disabled
        case regular
        case error

        var textColor: UIColor {
            switch self {
            case .disabled: return .themeGray
            case .regular: return .themeLeah
            case .error: return .themeLucian
            }
        }
    }

    struct Value {
        let text: String
        let type: ValueType
    }

}
