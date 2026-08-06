import BigInt
import Foundation
import Testing
@testable import WalletCore

struct ThorChainSendPreflightTests {
    @Test func exactBaseUnitBoundariesAreLossless() throws {
        #expect(try ThorChainSendHelper.baseUnits(Decimal(string: "1.00000000")!) == 100_000_000)
        #expect(try ThorChainSendHelper.baseUnits(Decimal(string: "0.00000001")!) == 1)
        #expect(try ThorChainSendHelper.baseUnits(Decimal(string: "0.00000010")!) == 10)
        #expect(try ThorChainSendHelper.baseUnits(Decimal(string: "1.23000000")!) == 123_000_000)
    }

    @Test func excessivePrecisionFailsClosed() {
        do {
            _ = try ThorChainSendHelper.baseUnits(Decimal(string: "0.000000001")!)
            Issue.record("sub-base-unit amount was accepted")
        } catch let error as ThorChainSendHelper.Error {
            #expect(error == .excessivePrecision)
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }
}
