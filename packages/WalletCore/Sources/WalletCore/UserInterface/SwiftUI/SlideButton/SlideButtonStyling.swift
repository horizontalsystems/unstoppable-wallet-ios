import SwiftUI

public struct SlideButtonStyling {
    public init(
        indicatorSize: CGFloat = .buttonSize64,
        indicatorColorStyle: ColorStyle = .brand,
        indicatorBrightness: Double = 0.0,
        backgroundColor: Color = .themeBlade,
        start: String = "",
        end: String = "",
        success: String = "",
        textColorStyle: ColorStyle = .secondary,
        textStyle: TextStyle = .headlineB,
        indicator: String = "arrow_m_right",
        indicatorSuccess: String = "check",
        indicatorIconColorStyle: ColorStyle = .white,
        textHiddenBehindIndicator: Bool = true,
        textShimmers: Bool = true,
        fillOpacity: Double = 0.8,
        disabledColorStyle: ColorStyle = .andy,
        disabledIconColorStyle: ColorStyle = .secondary
    ) {
        self.indicatorSize = indicatorSize
        self.indicatorBrightness = indicatorBrightness

        self.indicatorColorStyle = indicatorColorStyle
        self.backgroundColor = backgroundColor
        startText = start
        endText = end
        successText = success
        self.textColorStyle = textColorStyle
        self.textStyle = textStyle

        self.indicator = indicator
        self.indicatorSuccess = indicatorSuccess
        self.indicatorIconColorStyle = indicatorIconColorStyle
        self.textHiddenBehindIndicator = textHiddenBehindIndicator
        self.textShimmers = textShimmers
        self.fillOpacity = fillOpacity
        self.disabledColorStyle = disabledColorStyle
        self.disabledIconColorStyle = disabledIconColorStyle
    }

    var indicatorSize: CGFloat
    var indicatorBrightness: Double

    var indicatorColorStyle: ColorStyle
    var backgroundColor: Color
    var startText: String
    var endText: String
    var successText: String
    var textColorStyle: ColorStyle
    var textStyle: TextStyle

    var indicator: String
    var indicatorSuccess: String
    var indicatorIconColorStyle: ColorStyle

    var textHiddenBehindIndicator: Bool
    var textShimmers: Bool
    var fillOpacity: Double
    var disabledColorStyle: ColorStyle
    var disabledIconColorStyle: ColorStyle

    public static var `default`: Self {
        .init()
    }

    public static func text(start: String, end: String? = nil, success: String? = nil) -> Self {
        .init(start: start, end: end ?? start, success: success ?? end ?? start)
    }
}
