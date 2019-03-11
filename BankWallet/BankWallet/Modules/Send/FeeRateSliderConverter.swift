import Foundation

class FeeRateSliderConverter: IFeeRateSliderConverter {
    let a: Int
    let highestNew: Int

    init?(feeRates: FeeRates) {
        a = feeRates.lowest
        let b = feeRates.medium
        let c = feeRates.highest

        let d = Float(c - a)
        let d1 = Float(b - a)

        guard d > 0, d1 > 0 else  {
            return nil
        }

        let pos = d1 / d * 100
        let pos1 = min(max(20, pos), 80)
        highestNew = Int(d1 * 100 / pos1)

        guard highestNew > 0 else  {
            return nil
        }
    }

    func percent(for unit: Int) -> Int {
        return (unit - a) * 100 / highestNew
    }

    func unit(for percent: Int) -> Int {
        return highestNew * percent / 100 + a
    }

}
