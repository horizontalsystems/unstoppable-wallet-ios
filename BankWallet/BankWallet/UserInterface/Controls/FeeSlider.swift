import UIKit

class FeeSlider: UISlider {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    required init() {
        super.init(frame: CGRect.zero)

        minimumValueImage = UIImage(named: "Fee Slider Slow")
        maximumValueImage = UIImage(named: "Fee Slider Fast")
        maximumValue = 4
        minimumValue = 0
        value = 2
        minimumTrackTintColor = .clear
        maximumTrackTintColor = .clear
        setThumbImage(UIImage(named: "Fee Slider Thumb Image")?.tinted(with: SendTheme.feeSliderThumbColor), for: .normal)

        let slideBar = UIView()
        addSubview(slideBar)
        slideBar.backgroundColor = SendTheme.feeSliderTintColor
        slideBar.isUserInteractionEnabled = false
        slideBar.clipsToBounds = false
        slideBar.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(34)
            maker.trailing.equalToSuperview().offset(-34)
            maker.height.equalTo(SendTheme.slideBarHeight)
            maker.centerY.equalToSuperview().offset(1)
        }

        for i in 0..<5 {
            let stepView = UIView()
            slideBar.addSubview(stepView)
            stepView.backgroundColor = SendTheme.feeSliderTintColor
            stepView.isUserInteractionEnabled = false
            stepView.layer.cornerRadius = SendTheme.stepViewSideSize / 2
            stepView.snp.makeConstraints { maker in
                maker.centerY.equalTo(slideBar)
                maker.size.equalTo(SendTheme.stepViewSideSize)
                if i == 0 {
                    maker.leading.equalTo(slideBar)
                } else if i == 4 {
                    maker.trailing.equalTo(slideBar)
                } else {
                    let multiplier: CGFloat = CGFloat(i) * 0.25
                    maker.centerX.equalTo(slideBar.snp.trailing).multipliedBy(multiplier)
                }
            }
        }
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return true
    }

}
