import Foundation

extension String {

    var reversedData: Data? {
        return Data(hex: self).map { Data($0.reversed()) }
    }

}
