import Foundation

enum AddressUriFixtures {
    static let evmRecipient = "0xA24c159C7f1E4A04dab7c364C2A8b87b3dBa4cd1"
    static let usdtContract = "0xdac17f958d2ee523a2206206994597c13d831ec7"
    static let usdcContract = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"

    static let btc = "bc1qxt5u5swx3sk6y2923whr4tvjreza43g37czv67"
    static let ltc = "ltc1q05f90wt464h8dft9t7q9sp9n0qeprlv30070at"
    static let dash = "Xp24AqFUP9nF3ycLCmTDvgezxSt3RAKP2r"
    static let bchPrefix = "bitcoincash:qz6sy9fq66yvfl5mvpfv3v2nqw5pervvkc425nj9g0"
    static let ecashPrefix = "ecash:qp6t4rqd4qdlq0vlucjhucjxygn5969j3cdan6ykzr"

    static let zecShielded = "zs1jpd8u7zghtq5eg48l384y6fpy7cr0xmqehnw5mujpm8v2u7jr9a3j7luftqpthf6a8f720vdfyn"

    static let tron = "TQzANCd363w5CjRWDtswm8Y5nFPAdnwekF"
    static let ton = "UQAYLATDlfKgn3cKZAgznvowhXzpqgxrIicesxJfo9f6PN3k"
    static let xmrPrimary = "48edfHu7V9Z84YzzMa6fUueoELZ9ZRXq9VetWzYGzKt52XU5xvqgzYnDK9URnRoJMk1j8nLwEVsaSWJ4fhdUyZijBGUicoD"
    static let stellar = "GA5XIGA5C7QTPTWXQHY6MCJRMTRZDOSHR6EFIBNDQTCQHG262N4GGKTM"
    static let zano = "ZxDqGRfH6NEMR6jrYJp8jsqL3pyZQTPVwwbgyRk7uPnSv8M5jUYg83mPRD2Pdmjmh1JS9zSpFAtPpEFEgQTBpD4y2BSEm9V8z"
    static let solana = "DgeAF3yWjZWSb6AKgKouuUfk4EDXsrgFVnUyVwsE3RiE"

    static func decimal(_ string: String) -> Decimal {
        guard let value = Decimal(string: string) else {
            preconditionFailure("Invalid decimal literal in test fixture: \(string)")
        }
        return value
    }
}
