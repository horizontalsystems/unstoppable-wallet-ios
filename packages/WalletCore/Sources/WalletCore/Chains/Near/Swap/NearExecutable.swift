import Foundation
import MarketKit

public struct NearExecutable: ISwapExecutable {
    public let token: Token
    public let address: String
    public let amount: Decimal
    /// What the confirmation showed: a token send is refused without it, and the kit refuses one
    /// whose storage deposit changed since.
    let estimate: NearSendEstimate?
}
