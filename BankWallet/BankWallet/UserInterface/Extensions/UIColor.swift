import UIKit

extension UIColor {
    static var crypto_Dark_MidLightBackground: UIColor { return App.shared.localStorage.lightMode ? .cryptoMidLightBackground : .cryptoDark }
    static var crypto_Dark_LightBackground: UIColor { return App.shared.localStorage.lightMode ? .cryptoLightBackground : .cryptoDark }
    static var crypto_Dark_Bars: UIColor { return App.shared.localStorage.lightMode ? .cryptoBars : .cryptoDark }
    static var crypto_Bars_Dark: UIColor { return App.shared.localStorage.lightMode ? .cryptoDark : .cryptoBars }
    static var crypto_Dark96_Bars96: UIColor { return App.shared.localStorage.lightMode ? .cryptoBars96 : .cryptoDark96 }
    static var crypto_Steel20_White: UIColor { return App.shared.localStorage.lightMode ? .white : .cryptoSteel20 }
    static var crypto_Steel40OnDark_Steel20: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20 : .cryptoSteel40OnDark }
    static var crypto_Steel20_Steel40: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20 : .cryptoSteel40 }
    static var crypto_Steel20_Clear: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20 : .clear }
    static var crypto_White_Black: UIColor { return App.shared.localStorage.lightMode ? .black : white }
    static var crypto_Bars_Black: UIColor { return App.shared.localStorage.lightMode ? .black : cryptoBars }
    static var crypto_Black_Bars: UIColor { return App.shared.localStorage.lightMode ? .cryptoBars : black }
    static var crypto_White_Steel20: UIColor { return App.shared.localStorage.lightMode ? .white : cryptoSteel20 }
    static var crypto_Clear_White: UIColor { return App.shared.localStorage.lightMode ? .white : .clear }
    static var crypto_Silver_Black: UIColor { return App.shared.localStorage.lightMode ? .black : .cryptoSilver }
    static var crypto_Steel20_LightBackground: UIColor { return App.shared.localStorage.lightMode ? .cryptoLightBackground : .cryptoSteel20 }
    static var crypto_Steel40_LightGray: UIColor { return App.shared.localStorage.lightMode ? .cryptoLightGray : .cryptoSteel40 }
    static var crypto_White_Gray: UIColor { return App.shared.localStorage.lightMode ? .white : .cryptoGray }
    static var crypto_Dark_White: UIColor { return App.shared.localStorage.lightMode ? .white: .cryptoDark }
    static var crypto_Dark50_White50: UIColor { return App.shared.localStorage.lightMode ? .cryptoWhite50: .cryptoDark50 }
    static var crypto_SteelDark_White: UIColor { return App.shared.localStorage.lightMode ? .white: .cryptoSteelDark }
    static var crypto_SteelDark_Bars: UIColor { return App.shared.localStorage.lightMode ? .cryptoBars: .cryptoSteelDark }
    static var crypto_LightGray_SteelDark: UIColor { return App.shared.localStorage.lightMode ? .cryptoLightGray: .cryptoSteelDark }
    static var crypto_SteelDark_LightGray: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteelDark : .cryptoLightGray }
    static var crypto_Black20_Steel20: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20: .cryptoBlack20 }
    static var crypto_Black50_Steel20: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20: .cryptoBlack50 }

    static var crypto_Silver_Dark50: UIColor { return App.shared.localStorage.lightMode ? .cryptoDark50 : .cryptoSilver50 }

    static let cryptoBars: UIColor = UIColor(named: "Bars") ?? .black
    static let cryptoBars96: UIColor = UIColor(named: "Bars96") ?? .black
    static let cryptoDark: UIColor = UIColor(named: "Dark") ?? .black
    static let cryptoDark50: UIColor = UIColor(named: "Dark50") ?? .black
    static let cryptoDark96: UIColor = UIColor(named: "Dark96") ?? .black
    static let cryptoGray: UIColor = UIColor(named: "Gray") ?? .black
    static let cryptoGray50: UIColor = UIColor(named: "Gray50") ?? .black
    static let cryptoGreen: UIColor = UIColor(named: "Green") ?? .black
    static let cryptoGreen50: UIColor = UIColor(named: "Green50") ?? .black
    static let cryptoGreenPressed: UIColor = UIColor(named: "GreenPressed") ?? .black
    static let cryptoGreen20: UIColor = UIColor(named: "Green20") ?? .black
    static let cryptoMidLightBackground: UIColor = UIColor(named: "MidLightBackground") ?? .black
    static let cryptoLightBackground: UIColor = UIColor(named: "LightBackground") ?? .black
    static let cryptoLightGray: UIColor = UIColor(named: "LightGray") ?? .black
    static let cryptoRed: UIColor = UIColor(named: "Red") ?? .black
    static let cryptoRedPressed: UIColor = UIColor(named: "RedPressed") ?? .black
    static let cryptoSilver: UIColor = UIColor(named: "Silver") ?? .black
    static let cryptoSilver50: UIColor = UIColor(named: "Silver50") ?? .black
    static let cryptoSteel20: UIColor = UIColor(named: "Steel20") ?? .black
    static let cryptoSteel20OnDark: UIColor = UIColor(named: "Steel20OnDark") ?? .black
    static let cryptoSteel40OnDark: UIColor = UIColor(named: "Steel40OnDark") ?? .black
    static let cryptoBlack20: UIColor = UIColor(named: "Black20") ?? .black
    static let cryptoBlack50: UIColor = UIColor(named: "Black50") ?? .black
    static let cryptoSteel40: UIColor = UIColor(named: "Steel40") ?? .black
    static let cryptoSteelDark: UIColor = UIColor(named: "SteelDark") ?? .black
    static let cryptoWhite50: UIColor = UIColor(named: "White50") ?? .black
    static let cryptoWhite60: UIColor = UIColor(named: "White60") ?? .black
    static let cryptoYellow: UIColor = UIColor(named: "Yellow") ?? .black
    static let cryptoYellow50: UIColor = UIColor(named: "Yellow50") ?? .black
    static let cryptoYellow40: UIColor = UIColor(named: "Yellow40") ?? .black
    static let cryptoYellowPressed: UIColor = UIColor(named: "YellowPressed") ?? .black
}

extension UIColor {
    static var appJacob: UIColor { return App.shared.localStorage.lightMode ? .appYellowL : .appYellowD }
    static var appRemus: UIColor { return App.shared.localStorage.lightMode ? .appGreenL : .appGreenD }
    static var appLucian: UIColor { return App.shared.localStorage.lightMode ? .appRedL : .appRedD }
    static var appOz: UIColor { return App.shared.localStorage.lightMode ? .appDark : .appLight }
    static var appLeah: UIColor { return App.shared.localStorage.lightMode ? .appSteelDark : .appSteelLight }
    static var appJeremy: UIColor { return App.shared.localStorage.lightMode ? .appSteelLight : .appSteel20 }
    static var appElena: UIColor { return App.shared.localStorage.lightMode ? .appLightGrey : .appSteel20 }
    static var appLawrence: UIColor { return App.shared.localStorage.lightMode ? .appWhite : .appSteel20 }
    static var appClaude: UIColor { return App.shared.localStorage.lightMode ? .appWhite : .appDark }

    static let appYellowD: UIColor = UIColor(named: "App Yellow D") ?? .black
    static let appYellowL: UIColor = UIColor(named: "App Yellow L") ?? .black
    static let appGreenD: UIColor = UIColor(named: "App Green D") ?? .black
    static let appGreenL: UIColor = UIColor(named: "App Green L") ?? .black
    static let appRedD: UIColor = UIColor(named: "App Red D") ?? .black
    static let appRedL: UIColor = UIColor(named: "App Red L") ?? .black
    static let appBlack: UIColor = UIColor(named: "App Black") ?? .black
    static let appGrey: UIColor = UIColor(named: "App Grey") ?? .black
    static let appLightGrey: UIColor = UIColor(named: "App Light Grey") ?? .black
    static let appWhite: UIColor = UIColor(named: "App White") ?? .black
    static let appSteelDark: UIColor = UIColor(named: "App Steel Dark") ?? .black
    static let appSteelLight: UIColor = UIColor(named: "App Steel Light") ?? .black
    static let appDark: UIColor = UIColor(named: "App Dark") ?? .black
    static let appLight: UIColor = UIColor(named: "App Light") ?? .black
    static let appBlack50: UIColor = UIColor(named: "App Black 50") ?? .black
    static let appWhite50: UIColor = UIColor(named: "App White 50") ?? .black
    static let appSteel20: UIColor = UIColor(named: "App Steel 20") ?? .black
    static let appGrey50: UIColor = UIColor(named: "App Grey 50") ?? .black
    static let appYellow50: UIColor = UIColor(named: "App Yellow 50") ?? .black
    static let appGreen50: UIColor = UIColor(named: "App Green 50") ?? .black
}