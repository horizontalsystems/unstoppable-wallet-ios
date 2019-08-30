import UIKit
import SnapKit
import UIExtensions

class SendFeePriorityView: UIView {
    private let delegate: ISendFeePriorityViewDelegate

    private let feePriorityTitleLabel = UILabel()
    private let feePriorityValueLabel = UILabel()

    private let wrapperView = RespondView()

    private let dropDownImageView = UIImageView()
    private let lineView = UIView()

    init(delegate: ISendFeePriorityViewDelegate) {
        self.delegate = delegate

        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.feePriorityHeight)
        }

        backgroundColor = .clear

        addSubview(feePriorityTitleLabel)
        addSubview(wrapperView)
        addSubview(lineView)

        wrapperView.addSubview(feePriorityValueLabel)
        wrapperView.addSubview(dropDownImageView)

        feePriorityTitleLabel.text = "send.tx_speed".localized + ":"
        feePriorityTitleLabel.font = SendTheme.feePriorityTitleFont
        feePriorityTitleLabel.textColor = SendTheme.feePriorityTitleColor
        feePriorityTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.feePriorityTitleTopMargin)
        }

        wrapperView.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.feePriorityWrapperHeight)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.centerY.equalTo(feePriorityTitleLabel.snp.centerY)
        }

        setPriority()
        feePriorityValueLabel.font = SendTheme.feePriorityValueFont
        feePriorityValueLabel.textColor = SendTheme.feePriorityValueColor
        feePriorityValueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.feePriorityValueLeftMargin)
            maker.trailing.equalTo(dropDownImageView.snp.leading).offset(-SendTheme.feePriorityValueRightMargin)
            maker.centerY.equalToSuperview()
            maker.height.equalToSuperview()
        }

        dropDownImageView.image = UIImage(named: "Drop Down")
        dropDownImageView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        lineView.backgroundColor = SendTheme.feePriorityLineColor
        lineView.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.feePriorityLineHeight)
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalTo(feePriorityTitleLabel.snp.bottom).offset(SendTheme.feePriorityLineTopMargin)
        }

        wrapperView.handleTouch = { [weak self] in
            self?.delegate.onFeePrioritySelectorTap()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func text(priority: FeeRatePriority) -> String {
        switch priority {
        case .high: return "send.tx_speed_high".localized
        case .medium: return "send.tx_speed_medium".localized
        case .low: return "send.tx_speed_low".localized            
        }
    }

}

extension SendFeePriorityView: ISendFeePriorityView {

    func setPriority() {
        feePriorityValueLabel.text = text(priority: delegate.feeRatePriority)
    }

}
