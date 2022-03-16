import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

class SendXFeeCell: BaseThemeCell {
    private let disposeBag = DisposeBag()

    init(viewModel: IFeeViewModel) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true
        set(backgroundStyle: .transparent, isFirst: true)

        CellBuilder.build(cell: self, elements: [.text, .text, .spinner20])

        bind(index: 0) { (component: TextComponent) in
            component.set(style: .d1)
            component.text = "send.fee".localized
        }

        subscribe(disposeBag, viewModel.valueDriver) { [weak self] value in
            self?.bind(index: 1) { (component: TextComponent) in
                if let value = value {
                    component.isHidden = false
                    switch value.type {
                    case .regular: component.set(style: .d1)
                    case .error: component.set(style: .d5)
                    }
                    component.text = value.text
                } else {
                    component.isHidden = true
                }
            }
        }

        subscribe(disposeBag, viewModel.spinnerVisibleDriver) { [weak self] visible in
            self?.bind(index: 2) { (component: SpinnerComponent) in
                component.isHidden = !visible
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
