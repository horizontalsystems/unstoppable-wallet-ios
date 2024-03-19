import SwiftUI
import UIKit

class TechnicalIndicatorSliderView: UIView {
    static let padding: CGFloat = .margin2
    static let sliderSize: CGFloat = 33
    static let height: CGFloat = sliderSize + 2 * padding

    static let sliderColor: [UIColor] = [
        .themeRedD,
        UIColor(hex: 0xFF7A00),
        .themeYellowD,
        .themeGreenD,
    ]

    private let sliderView = UIView()

    private(set) var sliderIndex: Int
    let sliderCount: Int

    var shift: CGFloat {
        guard !width.isZero else {
            return .zero
        }

        let index = sliderIndex % sliderCount
        let area = width - 2 * Self.padding - Self.sliderSize
        let distanceBetweenCenters = area / CGFloat(sliderCount - 1)

        return Self.padding + CGFloat(index) * distanceBetweenCenters
    }

    init(count: Int = 4, index: Int = 2) {
        sliderIndex = index
        sliderCount = count

        super.init(frame: .zero)

        backgroundColor = .clear

        let gradientView = SliderGradientView()
        addSubview(gradientView)
        gradientView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.height.equalTo(Self.height)
        }

        gradientView.clipsToBounds = true
        gradientView.cornerRadius = .cornerRadius8

        addSubview(sliderView)
        sliderView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(Self.padding)
            maker.leading.equalToSuperview().offset(Self.padding)
            maker.size.equalTo(Self.sliderSize)
        }

        sliderView.clipsToBounds = true
        sliderView.layer.cornerRadius = 6
        sliderView.backgroundColor = .themeRedD
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(index: Int) {
        sliderIndex = index
        sliderView.backgroundColor = Self.sliderColor.at(index: index) ?? .themeGray

        updateSlider()
    }

    private func updateSlider() {
        sliderView.snp.updateConstraints { maker in
            maker.leading.equalToSuperview().offset(shift)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateSlider()
    }
}

class SliderGradientView: UIView {
    static let colors: [UIColor] = [
        .themeRedD.withAlphaComponent(0.2),
        UIColor(hex: 0xFFD600).withAlphaComponent(0.2),
        .themeGreenD.withAlphaComponent(0.2),
    ]

    override func draw(_: CGRect) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = Self.colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradientLayer)
    }
}
