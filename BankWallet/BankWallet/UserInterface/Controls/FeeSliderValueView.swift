import UIKit
import SnapKit
import HUD

class FeeSliderValueView: UIView {
    private let feeRateLabel = UILabel()
    private let satByteLabel = UILabel()

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required public init() {
        super.init(frame: CGRect.zero)

        backgroundColor = .themeClaude
        addSubview(feeRateLabel)
        feeRateLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.centerX.equalToSuperview()
        }
        feeRateLabel.textAlignment = .center
        feeRateLabel.textColor = .themeLeah
        feeRateLabel.font = .body

        addSubview(satByteLabel)
        satByteLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(feeRateLabel.snp.bottom)
        }
        satByteLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        satByteLabel.text = "sat/byte"
        satByteLabel.font = .micro
        satByteLabel.textAlignment = .center
        satByteLabel.textColor = .themeGray
    }

    func set(value: String?) {
        feeRateLabel.text = value
    }

}

extension FeeSliderValueView: HUDContentViewInterface {

    public func updateConstraints(forSize size: CGSize) {
        // do nothing
    }

    public var actions: [HUDTimeAction] {
        get { [] }
        set {}
    }   // ignore all actions on view

}
