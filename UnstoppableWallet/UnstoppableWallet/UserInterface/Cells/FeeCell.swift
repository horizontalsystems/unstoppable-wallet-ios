import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit


protocol IFeeViewModel {
    var maxFeeDriver: Driver<String?> { get }
    var editButtonVisibleDriver: Driver<Bool> { get }
}

class FeeCell: UITableViewCell {
    weak var delegate: IFeeSliderCellDelegate?

    private let disposeBag = DisposeBag()
    var titleType: TitleType = .fee {
        didSet {
            title = titleType.value
        }
    }

    var onTapEdit: (() -> ())? {
        didSet {
            buttonComponent.onTap = onTapEdit
        }
    }

    var isVisible = true

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let buttonComponent = TransparentIconButtonComponent()

    init(feeViewModel: IFeeViewModel) {
        super.init(style: .default, reuseIdentifier: nil)

        title = titleType.value

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.textColor = .themeGray
        titleLabel.font = .subhead2

        contentView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.centerY.equalToSuperview()
        }

        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        valueLabel.textColor = .themeGray
        valueLabel.font = .subhead2

        contentView.addSubview(buttonComponent)
        buttonComponent.snp.makeConstraints { maker in
            maker.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        buttonComponent.button.set(image: UIImage(named: "edit2_20"))

        feeViewModel.maxFeeDriver
                .drive(onNext: { [weak self] status in
                    self?.isVisible = status != nil
                    self?.value = status
                })
                .disposed(by: disposeBag)

        feeViewModel.editButtonVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.buttonComponent.isHidden = !visible
                })
                .disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var value: String? {
        get { valueLabel.text }
        set { valueLabel.text = newValue }
    }

    var valueColor: UIColor {
        get { valueLabel.textColor }
        set { valueLabel.textColor = newValue }
    }

    var cellHeight: CGFloat {
        isVisible ? 29 : 0
    }

    private func openFeeInfo() {
        let infoController = InfoModule.viewController(dataSource: FeeInfoDataSource())
        delegate?.open(viewController: ThemeNavigationController(rootViewController: infoController))
    }

}

extension FeeCell {

    enum TitleType {
        case fee
        case maxFee
        case estimatedFee

        var value: String {
            switch self {
            case .fee: return "send.network_fee".localized
            case .maxFee: return "send.max_fee".localized
            case .estimatedFee: return "send.estimated_fee".localized
            }
        }
    }

}
