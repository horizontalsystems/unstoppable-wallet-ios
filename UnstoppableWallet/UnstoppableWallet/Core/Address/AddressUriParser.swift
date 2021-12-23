import Foundation

class AddressUriParser: IAddressUriParser {
    fileprivate static let parameterVersion = "version"
    fileprivate static let parameterAmount = "amount"
    fileprivate static let parameterLabel = "label"
    fileprivate static let parameterMessage = "message"

    private let validScheme: String?
    private let removeScheme: Bool

    init(validScheme: String?, removeScheme: Bool) {
        self.validScheme = validScheme
        self.removeScheme = removeScheme
    }

    func parse(paymentAddress: String) -> AddressData {
        var parsedString = paymentAddress
        var address: String

        var version: String?
        var amount: Double?
        var label: String?
        var message: String?

        var parameters = [String: String]()
        var parametersParts = [String]()

        let schemeSeparatedParts = paymentAddress.components(separatedBy: ":")
        // check exist scheme. If scheme equal network scheme, remove scheme as stated in flag. Otherwise, leave wrong scheme to make throw in validator
        if schemeSeparatedParts.count >= 2 {
            if  validScheme == nil || schemeSeparatedParts[0].lowercased() == validScheme {
                parsedString = removeScheme ? schemeSeparatedParts[1] : paymentAddress
            } else {
                parsedString = paymentAddress
            }
        }

        // check exist version
        var versionSeparatedParts = parsedString.components(separatedBy: CharacterSet(charactersIn: ";?"))
        guard versionSeparatedParts.count >= 2 else {
            address = parsedString

            return AddressData(address: address)
        }
        address = versionSeparatedParts.removeFirst()
        if let firstPart = versionSeparatedParts.first?.lowercased(), firstPart.range(of: AddressUriParser.parameterVersion) != nil {
            parametersParts.append(firstPart)

            versionSeparatedParts.removeFirst(1)
        }

        // parsing all parameters
        if let parameters = versionSeparatedParts.first?.components(separatedBy: CharacterSet(charactersIn: "&")) {
            parametersParts.append(contentsOf: parameters)
        }

        parametersParts.forEach { parameter in
            let parts = parameter.components(separatedBy: "=")
            if parts.count == 2 {
                switch parts[0] {
                case AddressUriParser.parameterVersion: version = parts[1]
                case AddressUriParser.parameterAmount: amount = Double(parts[1]) ?? nil
                case AddressUriParser.parameterLabel: label = parts[1].removingPercentEncoding
                case AddressUriParser.parameterMessage: message = parts[1].removingPercentEncoding
                default: parameters[parts[0]] = parts[1].removingPercentEncoding
                }
            }
        }

        return AddressData(address: address, version: version, amount: amount, label: label, message: message, parameters: parameters.isEmpty ? nil : parameters)
    }

}
