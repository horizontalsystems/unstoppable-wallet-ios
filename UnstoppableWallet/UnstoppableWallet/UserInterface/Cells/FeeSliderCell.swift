import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

struct FeeSliderViewItem {
    let initialValue: Int
    let range: ClosedRange<Int>
}

protocol IFeeSliderCellDelegate: AnyObject {
    func open(viewController: UIViewController)
}

protocol IDynamicHeightCellDelegate: AnyObject {
    func onChangeHeight()
}

class FeeSliderCell: UITableViewCell {
    private let feeSliderWrapper = FeeSliderWrapper()

    private let disposeBag = DisposeBag()

    var isVisible = true
    var onFinishTracking: ((Int) -> ())?

    init(sliderDriver: Driver<FeeSliderViewItem?>) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(feeSliderWrapper)
        feeSliderWrapper.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        feeSliderWrapper.finishTracking = { [weak self] value in
            self?.onFinishTracking?(value)
        }

        subscribe(disposeBag, sliderDriver) { [weak self] viewItem in
                    if let viewItem = viewItem {
                        self?.feeSliderWrapper.set(value: viewItem.initialValue, range: viewItem.range, description: "gwei")
                        self?.feeSliderWrapper.isHidden = false
                    } else {
                        self?.feeSliderWrapper.isHidden = true
                    }
                }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension FeeSliderCell {

    var cellHeight: CGFloat {
        35
    }

}
