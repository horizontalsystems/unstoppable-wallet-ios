import Foundation

class CurrentDateProvider: ICurrentDateProvider {
    var currentDate: Date {
        return Date()
    }
}
