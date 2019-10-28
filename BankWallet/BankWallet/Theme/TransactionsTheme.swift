import UIKit

class TransactionsTheme {
    static let dateLabelFont = UIFont.appBody
    static var dateLabelTextColor: UIColor { return .crypto_Silver_Black }
    static var dateLabelTextColor50: UIColor { return .crypto_Silver_Dark50 }
    static let currencyAmountLabelFont: UIFont = .systemFont(ofSize: 22, weight: .semibold)
    static let incomingTextColor = UIColor.cryptoGreen
    static let incomingTextColor50 = UIColor.cryptoGreen50
    static let outgoingTextColor = UIColor.cryptoYellow
    static let outgoingTextColor50 = UIColor.cryptoYellow50
    static let cellHeight: CGFloat = 72
    static var cellBackground: UIColor { return .crypto_Dark_White }
    static let cellMediumMargin: CGFloat = 12
    static let cellHighlightBackgroundColor = UIColor.cryptoSteel20
    static let amountLabelFont = UIFont.appSubhead2
    static let fiatAmountLabelColor = UIColor.cryptoGray
    static let fiatAmountLabelColor50 = UIColor.cryptoGray50
}
