import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

protocol IFeeViewModel {
    var title: String { get }
    var valueDriver: Driver<FeeCell.Value?> { get }
    var spinnerVisibleDriver: Driver<Bool> { get }
}

extension IFeeViewModel {

    var title: String {
        "fee_settings.max_fee".localized
    }

}

class FeeCell: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()

    private let viewModel: IFeeViewModel

    init(viewModel: IFeeViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true
        set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

        CellBuilder.build(cell: self, elements: [.image20, .text, .text, .spinner20])

        bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "circle_information_20")
        })

        bind(index: 1) { (component: TextComponent) in
            component.set(style: .d1)
            component.text = viewModel.title
        }

        subscribe(disposeBag, viewModel.valueDriver) { [weak self] value in
            self?.bind(index: 2) { (component: TextComponent) in
                if let value = value {
                    component.isHidden = false
                    component.set(style: value.type.style)
                    component.text = value.text
                } else {
                    component.isHidden = true
                }
            }
        }

        subscribe(disposeBag, viewModel.spinnerVisibleDriver) { [weak self] visible in
            self?.bind(index: 3) { (component: SpinnerComponent) in
                component.isHidden = !visible
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension FeeCell {

    enum ValueType {
        case disabled
        case regular
        case error

        var style: TextComponent.Style {
            switch self {
            case .disabled: return .c1
            case .regular: return .c2
            case .error: return .c5
            }
        }
    }

    struct Value {
        let text: String
        let type: ValueType
    }

}
