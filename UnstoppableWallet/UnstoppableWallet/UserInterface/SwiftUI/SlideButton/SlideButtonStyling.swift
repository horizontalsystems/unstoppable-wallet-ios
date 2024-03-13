import SwiftUI
import ThemeKit

public struct SlideButtonStyling {
    public init(
        indicatorSize: CGFloat = .heightButton,
        indicatorColor: Color = .themeJacob,
        indicatorBrightness: Double = 0.0,
        backgroundColor: Color = .themeSteel20,
        start: String = "",
        end: String = "",
        success: String = "",
        textColor: Color = .themeGray,
        textFont: Font = .themeHeadline2,
        indicator: String = "arrow_medium_2_right_24",
        indicatorSuccess: String = "check_2_24",
        indicatorDisabled: String = "arrow_medium_2_right_24",
        textHiddenBehindIndicator: Bool = true,
        textShimmers: Bool = true
    ) {
        self.indicatorSize = indicatorSize
        self.indicatorBrightness = indicatorBrightness

        self.indicatorColor = indicatorColor
        self.backgroundColor = backgroundColor
        startText = start
        endText = end
        successText = success
        self.textColor = textColor
        self.textFont = textFont

        self.indicator = indicator
        self.indicatorSuccess = indicatorSuccess
        self.indicatorDisabled = indicatorDisabled
        self.textHiddenBehindIndicator = textHiddenBehindIndicator
        self.textShimmers = textShimmers
    }

    var indicatorSize: CGFloat
    var indicatorBrightness: Double

    var indicatorColor: Color
    var backgroundColor: Color
    var startText: String
    var endText: String
    var successText: String
    var textColor: Color
    var textFont: Font

    var indicator: String
    var indicatorSuccess: String
    var indicatorDisabled: String

    var textHiddenBehindIndicator: Bool
    var textShimmers: Bool

    public static let `default`: Self = .init()
    public static func text(start: String, end: String? = nil, success: String? = nil) -> Self {
        .init(start: start, end: end ?? start, success: success ?? end ?? start)
    }
}
