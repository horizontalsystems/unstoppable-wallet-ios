import SwiftUI
import UIExtensions
import UIKit

public extension Color {
    static let themeDark = Color("Dark")
    static let themeCarbon = Color("Carbon")
    static let themeSmoke = Color("Smoke")
    static let themeGray = Color("Gray")
    static let themeSteel = Color("Steel")
    static let themeLight = Color("SteelLight")
    static let themeBright = Color("Bright")

    static let themeLightGray = Color("LightGray")
    static let themeDarker = Color("Darker")
    static let themeYellow = Color("Yellow")
    static let themeGreen = Color("Green")
    static let themeRed = Color("Red")
    static let themeStronbuy = Color("Stronbuy")

    static let themeGray50 = Color.themeGray.opacity(0.5)
    static let themeYellow20 = Color.themeYellow.opacity(0.2)
    static let themeYellow50 = Color.themeYellow.opacity(0.5)
    static let themeRed50 = Color.themeRed.opacity(0.5)

    static let themeTyler = Color("Tyler")
    static let themeTyler96 = Color("Tyler96")
    static let themeLawrence = Color("Lawrence")
    static let themeBlade = Color("Blade")
    static let themeAndy = Color("Andy")
    static let themeLeah = Color("Leah")
    static let themeJacob = Color("Jacob")
    static let themeRemus = Color("Remus")
    static let themeLucian = Color("Lucian")

    static let themeBlackTenTwenty = Color("BlackTenTwenty")
    static let themeBran = Color("Bran")
    static let themeClaude = Color("Claude")
    static let themeHelsing = Color("Helsing")
    static let themeJeremy = Color("Jeremy")
    static let themeLaguna = Color("Laguna")
    static let themeNina = Color("Nina")
    static let themeRaina = Color("Raina")

    static var themeBackgroundFromGradient: Color { .themeTyler }
    static var themeBackgroundToGradient: Color { .themeHelsing }
    static var themeNavigationBarBackground: Color { .themeTyler96 }

    var pressed: Color { opacity(0.5) }
}

public extension UIColor {
    static let themeBlack = UIColor(hex: 0x000000)
    static let themeDark = UIColor(.themeDark)
    static let themeDark96 = UIColor(.themeDark).withAlphaComponent(0.96)
    static let themeCarbon = UIColor(.themeCarbon)
    static let themeSmoke = UIColor(.themeSmoke)
    static let themeGray = UIColor(.themeGray)
    static let themeSteel = UIColor(.themeSteel)
    static let themeLight = UIColor(.themeLight)
    static let themeBright = UIColor(.themeBright)

    static let themeYellowD = UIColor(hex: 0xFFB700)
    static let themeYellowL = UIColor(hex: 0xFF9D00)
    static let themeGreenD = UIColor(hex: 0x0AC18E)
    static let themeGreenL = UIColor(hex: 0x0AA177)
    static let themeRedD = UIColor(hex: 0xFF1539)
    static let themeRedL = UIColor(hex: 0xFF1500)
    static let themeOrange = UIColor(hex: 0xFE4A11)
    static let themeSunset = UIColor(hex: 0xFF2C00)

    static let themeIssykBlue = UIColor(hex: 0x3372FF)
    static let themeLightGray = UIColor(hex: 0xC8C7CC)
    static let themeWhite = UIColor(hex: 0xFFFFFF)
    static let themeSteelDark = UIColor(hex: 0x252933)
    static let themeSteelLight = UIColor(hex: 0xE1E1E5)
    static let themeDarker = UIColor(hex: 0x0F1014)
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
    static var themeTyler: UIColor { color(dark: .black, light: .themeBright) }
    static var themeTyler96: UIColor { color(dark: .black, light: .themeBright) }
    static var themeLawrence: UIColor { color(dark: .themeDark, light: .themeWhite) }
    static var themeBlade: UIColor { color(dark: .themeCarbon, light: .themeLight) }
    static var themeAndy: UIColor { color(dark: .themeSmoke, light: .themeSteel) }
    static var themeLeah: UIColor { color(dark: .themeBright, light: .themeDark) }

    static var themeJacob: UIColor { color(dark: .themeYellowD, light: .themeYellowL) }
    static var themeRemus: UIColor { color(dark: .themeGreenD, light: .themeGreenL) }
    static var themeLucian: UIColor { color(dark: .themeRedD, light: .themeRedL) }

    static var themeJeremy: UIColor { color(dark: .themeBlade, light: .themeSteelLight) }
    static var themeElena: UIColor { color(dark: .themeBlade, light: .themeLightGray) }
    static var themeLawrencePressed: UIColor { color(dark: .themeLawrence.pressed, light: .themeLawrence.pressed) }
    static var themeClaude: UIColor { color(dark: .themeDark, light: .themeWhite) }
    static var themeNina: UIColor { color(dark: .themeWhite50, light: .themeBlack50) }
    static var themeHelsing: UIColor { color(dark: .themeDark, light: .themeSteelLight) }
    static var themeCassandra: UIColor { color(dark: .themeDark, light: .themeLightGray) }
    static var themeRaina: UIColor { color(dark: .themeBlade, light: .themeWhite50) }
    static var themeBran: UIColor { color(dark: .themeLightGray, light: .themeDark) }
    static var themeBlake: UIColor { color(dark: .themeSteelDark10, light: .themeSteelLight10) }
    static var themeLaguna: UIColor { color(dark: .themeLagunaD, light: .themeLagunaL) }
    static var themeBlackTenTwenty: UIColor { color(dark: .themeBlack10, light: .themeBlack20) }

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
    static var themeTabBarBackground: UIColor { UIColor.themeBlade }
}
