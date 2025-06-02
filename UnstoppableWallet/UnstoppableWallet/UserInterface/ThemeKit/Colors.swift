import SwiftUI
import UIExtensions
import UIKit

public extension Color {
    static let themeGray = Color("Gray")
    static let themeLightGray = Color("LightGray")
    static let themeDark = Color("Dark")
    static let themeDarker = Color("Darker")
    static let themeSteel = Color("Steel")
    static let themeSteelLight = Color("SteelLight")
    static let themeYellow = Color("Yellow")
    static let themeGreen = Color("Green")
    static let themeRed = Color("Red")
    static let themeStronbuy = Color("Stronbuy")

    static let themeGray50 = Color.themeGray.opacity(0.5)
    static let themeSteel10 = Color.themeSteel.opacity(0.1)
    static let themeSteel20 = Color.themeSteel.opacity(0.2)
    static let themeSteel30 = Color.themeSteel.opacity(0.3)
    static let themeYellow20 = Color.themeYellow.opacity(0.2)
    static let themeYellow50 = Color.themeYellow.opacity(0.5)
    static let themeRed50 = Color.themeRed.opacity(0.5)

    static let themeJacob = Color("Jacob")
    static let themeRemus = Color("Remus")
    static let themeLucian = Color("Lucian")
    static let themeLeah = Color("Leah")
    static let themeAndy = Color("Andy")
    static let themeBlackTenTwenty = Color("BlackTenTwenty")
    static let themeBran = Color("Bran")
    static let themeClaude = Color("Claude")
    static let themeHelsing = Color("Helsing")
    static let themeJeremy = Color("Jeremy")
    static let themeLaguna = Color("Laguna")
    static let themeLawrence = Color("Lawrence")
    static let themeLawrencePressed = Color("LawrencePressed")
    static let themeNina = Color("Nina")
    static let themeRaina = Color("Raina")
    static let themeTyler = Color("Tyler")
    static let themeTyler96 = Color("Tyler96")

    static var themeBackgroundFromGradient: Color { .themeTyler }
    static var themeBackgroundToGradient: Color { .themeHelsing }
    static var themeNavigationBarBackground: Color { .themeTyler96 }

    static let themeBlade = Color("Blade")

    var pressed: Color { opacity(0.5) }
}

public extension UIColor {
    static let themeYellowD = UIColor(hex: 0xFFA800)
    static let themeYellowL = UIColor(hex: 0xFF8A00)
    static let themeGreenD = UIColor(hex: 0x05C46B)
    static let themeGreenL = UIColor(hex: 0x04AD5F)
    static let themeRedD = UIColor(hex: 0xF43A4F)
    static let themeRedL = UIColor(hex: 0xFF3D43)
    static let themeBlack = UIColor(hex: 0x000000)
    static let themeIssykBlue = UIColor(hex: 0x3372FF)
    static let themeGray = UIColor(hex: 0x808085)
    static let themeLightGray = UIColor(hex: 0xC8C7CC)
    static let themeWhite = UIColor(hex: 0xFFFFFF)
    static let themeSteelDark = UIColor(hex: 0x252933)
    static let themeSteelLight = UIColor(hex: 0xE1E1E5)
    static let themeDark = UIColor(hex: 0x13151A)
    static let themeDark96 = UIColor(hex: 0x13151A, alpha: 0.96)
    static let themeDarker = UIColor(hex: 0x0F1014)
    static let themeLight = UIColor(hex: 0xF0F0F0)
    static let themeLight96 = UIColor(hex: 0xF0F0F0, alpha: 0.96)
    static let themeBlack10 = UIColor(hex: 0x000000, alpha: 0.1)
    static let themeBlack20 = UIColor(hex: 0x000000, alpha: 0.2)
    static let themeBlack50 = UIColor(hex: 0x000000, alpha: 0.5)
    static let themeWhite50 = UIColor(hex: 0xFFFFFF, alpha: 0.5)
    static let themeSteel10 = UIColor(hex: 0x73798C, alpha: 0.1)
    static let themeSteel20 = UIColor(hex: 0x73798C, alpha: 0.2)
    static let themeSteel30 = UIColor(hex: 0x73798C, alpha: 0.3)
    static let themeGray50 = UIColor(hex: 0x808085, alpha: 0.5)
    static let themeYellow50 = UIColor(hex: 0xFFA800, alpha: 0.5)
    static let themeYellow20 = UIColor(hex: 0xFFA800, alpha: 0.2)
    static let themeGreen50 = UIColor(hex: 0x05C46B, alpha: 0.5)
    static let themeRed50 = UIColor(hex: 0xF43A4F, alpha: 0.5)
    static let themeLawrencePressedD = UIColor(hex: 0x353842)
    static let themeLawrencePressedL = UIColor(hex: 0xE3E4E8)
    static let themeStronbuy = UIColor(hex: 0x1A60FF)
    static let themeSteelDark10 = UIColor(hex: 0x1C1F27)
    static let themeSteelLight10 = UIColor(hex: 0xD6D7DD)
    static let themeLagunaD = UIColor(hex: 0x4A98E9)
    static let themeLagunaL = UIColor(hex: 0x4692DA)
}

public extension UIColor {
    static var themeJacob: UIColor { color(dark: .themeYellowD, light: .themeYellowL) }
    static var themeRemus: UIColor { color(dark: .themeGreenD, light: .themeGreenL) }
    static var themeLucian: UIColor { color(dark: .themeRedD, light: .themeRedL) }
    static var themeLeah: UIColor { color(dark: .themeSteelLight, light: .themeSteelDark) }
    static var themeJeremy: UIColor { color(dark: .themeSteel20, light: .themeSteelLight) }
    static var themeElena: UIColor { color(dark: .themeSteel20, light: .themeLightGray) }
    static var themeLawrence: UIColor { color(dark: .themeSteelDark, light: .themeWhite) }
    static var themeLawrencePressed: UIColor { color(dark: .themeLawrencePressedD, light: .themeLawrencePressedL) }
    static var themeClaude: UIColor { color(dark: .themeDark, light: .themeWhite) }
    static var themeAndy: UIColor { color(dark: .themeBlack50, light: .themeSteel20) }
    static var themeTyler: UIColor { color(dark: .themeDark, light: .themeLight) }
    static var themeTyler96: UIColor { color(dark: .themeDark96, light: .themeLight96) }
    static var themeNina: UIColor { color(dark: .themeWhite50, light: .themeBlack50) }
    static var themeHelsing: UIColor { color(dark: .themeDark, light: .themeSteelLight) }
    static var themeCassandra: UIColor { color(dark: .themeDark, light: .themeLightGray) }
    static var themeRaina: UIColor { color(dark: .themeSteel10, light: .themeWhite50) }
    static var themeBran: UIColor { color(dark: .themeLightGray, light: .themeDark) }
    static var themeBlake: UIColor { color(dark: .themeSteelDark10, light: .themeSteelLight10) }
    static var themeLaguna: UIColor { color(dark: .themeLagunaD, light: .themeLagunaL) }
    static var themeBlackTenTwenty: UIColor { color(dark: .themeBlack10, light: .themeBlack20) }

    static var themeBlade: UIColor { color(dark: .themeBlack10, light: .themeBlack20) }
    var pressed: UIColor { withAlphaComponent(0.5) }

    private static func color(dark: UIColor, light: UIColor) -> UIColor {
        UIColor { traits in
            switch ThemeManager.shared.themeMode {
            case .dark: return dark
            case .light: return light
            case .system: return traits.userInterfaceStyle == .dark ? dark : light
            }
        }
    }
}

public extension UIColor {
    static var themeBackgroundFromGradient: UIColor { .themeTyler }
    static var themeBackgroundToGradient: UIColor { .themeHelsing }

    static var themeInputFieldTintColor: UIColor { .themeJacob }
    static var themeNavigationBarBackground: UIColor { UIColor.themeTyler96 }
}
