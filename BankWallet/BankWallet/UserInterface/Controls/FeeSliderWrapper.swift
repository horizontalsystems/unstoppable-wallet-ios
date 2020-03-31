import UIKit

class FeeSliderWrapper: UIView {

    private let slider = FeeSlider()
    private let minimumLabel = UILabel()
    private let maximumLabel = UILabel()

    var onTracking: ((Int, CGPoint) -> ())?
    var finishTracking: ((Int) -> ())?

    var sliderRange: ClosedRange<Int> {
        Int(slider.minimumValue)...Int(slider.maximumValue)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    required init() {
        super.init(frame: CGRect.zero)

        addSubview(slider)
        addSubview(minimumLabel)
        addSubview(maximumLabel)

        slider.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(minimumLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalTo(maximumLabel.snp.leading).offset(-CGFloat.margin2x)
        }
        slider.onTracking = { [weak self] value, position in
            self?.onTracking?(value, position)
        }
        slider.finishTracking = { [weak self] value in
            self?.finishTracking?(value)
        }

        minimumLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalTo(slider)
        }
        minimumLabel.textColor = .themeGray
        minimumLabel.font = .subhead2
        minimumLabel.text = "-"
        minimumLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        maximumLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.centerY.equalTo(slider)
        }
        maximumLabel.textColor = .themeGray
        maximumLabel.font = .subhead2
        maximumLabel.textAlignment = .right
        maximumLabel.text = "+"
        maximumLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    func set(value: Int, range: ClosedRange<Int>) {
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
    }

}
