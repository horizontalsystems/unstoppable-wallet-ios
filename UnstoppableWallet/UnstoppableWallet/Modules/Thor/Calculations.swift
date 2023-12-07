
import Foundation

extension Thorchain {
    // MARK: Stake Calculations
    // https://gitlab.com/thorchain/asgardex-common/asgardex-util/-/blob/master/src/calc/stake.ts
    
    public static func getStakeUnits(stake: StakeData, pool: PoolData) -> BaseAmount {
        // formula: ((R + T) (r T + R t))/(4 R T)
        // part1 * (part2 + part3) / denominator
        let r = stake.rune.amount
        let t = stake.asset.amount
        let R = pool.runeBalance.amount + r
        let T = pool.assetBalance.amount + t
        let part1 = R + T
        let part2 = r * T
        let part3 = R * t
        let numerator = part1 * (part2 + part3)
        let denominator = R * T * 4
        let result = numerator / denominator
        return BaseAmount(result)
    }
    
    public static func getPoolShare(unitData: UnitData, pool: PoolData) -> StakeData {
        // formula: (rune * part) / total; (asset * part) / total
        let units = unitData.stakeUnits.amount
        let total = unitData.totalUnits.amount
        let R = pool.runeBalance.amount
        let T = pool.assetBalance.amount
        let asset = T * units / total
        let rune = R * units / total
        return StakeData(asset: BaseAmount(asset), rune: BaseAmount(rune))
    }
    
    public static func getSlipOnStake(stake: StakeData, pool: PoolData) -> Decimal {
        // formula: (t * R - T * r)/ (T*r + R*T)
        let r = stake.rune.amount
        let t = stake.asset.amount
        let R = pool.runeBalance.amount
        let T = pool.assetBalance.amount
        let numerator = t * R - T * r
        let denominator = T * r + R * T
        // Convert to String for Decimal calculations
        if let numeratorDecimal : Decimal = Decimal(string: numerator.description), let denominatorDecimal : Decimal = Decimal(string: denominator.description) {
            // Try with Decimal if they decode properly
            let result = abs(numeratorDecimal / denominatorDecimal)
            return result
        } else {
            // Try with Double (less precision)
            let numeratorDouble = Double(numerator)
            let denominatorDouble = Double(denominator)
            let result = abs(numeratorDouble / denominatorDouble)
            return Decimal(result)
        }
    }
    
    // MARK: Swap Calculations
    // https://gitlab.com/thorchain/asgardex-common/asgardex-util/-/blob/master/src/calc/swap.ts


    public static func getSwapOutput(inputAmount: BaseAmount, pool: PoolData, toRune: Bool) -> BaseAmount {
        // formula: (x * X * Y) / (x + X) ^ 2
        let x = inputAmount.amount
        let X = toRune ? pool.assetBalance.amount : pool.runeBalance.amount // input is asset if toRune
        let Y = toRune ? pool.runeBalance.amount : pool.assetBalance.amount // output is rune if toRune
        let numerator = x * X * Y
        let denominator = (x+X).power(2)
        let result = numerator / denominator
        return BaseAmount(result)
    }

    public static func getSwapOutputWithFee(
        inputAmount: BaseAmount,
        pool: PoolData,
        toRune: Bool,
        transactionFee: BaseAmount = AssetAmount(1).baseAmount
    ) -> BaseAmount {
        // formula: getSwapOutput() - one RUNE
        let x = inputAmount.amount
        let r = getSwapOutput(inputAmount: inputAmount, pool: pool, toRune: toRune)
        let poolAfterTransaction: PoolData = toRune // used to get rune fee price after swap
            ? PoolData(
                assetBalance: BaseAmount(pool.assetBalance.amount + x), // add asset input amount to pool
                runeBalance: BaseAmount(pool.runeBalance.amount - r.amount) // get input price in RUNE and subtract from pool
            )
            : PoolData(
                assetBalance: BaseAmount(pool.assetBalance.amount - r.amount), // get input price in RUNE and subtract from pool
                runeBalance: BaseAmount(pool.runeBalance.amount + x) // add RUNE input amount to pool
            )
        let runeFee = toRune ? transactionFee : getValueOfRuneInAsset(inputRune: transactionFee, pool: poolAfterTransaction) // toRune its one Rune else its asset(oneRune)
        let result = r.amount - runeFee.amount // remove oneRune, or remove asset(oneRune)
        return BaseAmount(result)
    }
    
    public static func getSwapInput(toRune: Bool, pool: PoolData, outputAmount: BaseAmount) -> BaseAmount {
        // formula: (((X*Y)/y - 2*X) - sqrt(((X*Y)/y - 2*X)^2 - 4*X^2))/2
        // (part1 - sqrt(part1 - part2))/2
        let X = toRune ? pool.assetBalance.amount : pool.runeBalance.amount // input is asset if toRune
        let Y = toRune ? pool.runeBalance.amount : pool.assetBalance.amount // output is rune if toRune
        let y = outputAmount.amount
        let part1 = X * Y / y - (X * 2)
        let part2 = X * X * 4
        let result = (part1 - (part1.power(2) - part2).squareRoot()) / 2  // (part1 - sqrt(part1^2 - part2)) /2
        return BaseAmount(result)
    }

    /// Get slip, which is dependent on pool sizes. Output percentage 0.0 (0%) - 1.0 (100%)
    public static func getSwapSlip(inputAmount: BaseAmount, pool: PoolData, toRune: Bool) -> Decimal {
        // formula: (x) / (x + X)
        let x = inputAmount.amount
        let X = toRune ? pool.assetBalance.amount : pool.runeBalance.amount // input is asset if toRune
        let numeratorString = x.description
        let denominatorString = (x + X).description
        if let numeratorDecimal = Decimal(string: numeratorString), let denominatorDecimal = Decimal(string: denominatorString) {
            // Try decode from string to Decimal (better precision)
            return numeratorDecimal / denominatorDecimal
        } else {
            let result = Double(x) / Double(x + X)
            return Decimal(result)
        }
    }
    
    public static func getSwapFee(inputAmount: BaseAmount, pool: PoolData, toRune: Bool) -> BaseAmount  {
        // formula: (x * x * Y) / (x + X) ^ 2
        let x = inputAmount.amount
        let X = toRune ? pool.assetBalance.amount : pool.runeBalance.amount // input is asset if toRune
        let Y = toRune ? pool.runeBalance.amount : pool.assetBalance.amount // output is rune if toRune
        let numerator = x * x * Y
        let denominator = (x + X) * (x + X)
        let result = numerator / denominator
        return BaseAmount(result)
    }
    
    public static func getValueOfAssetInRune(inputAsset: BaseAmount, pool: PoolData) -> BaseAmount  {
        // formula: ((a * R) / A) => R per A (Runeper$)
        let t = inputAsset.amount
        let R = pool.runeBalance.amount
        let A = pool.assetBalance.amount
        let result = t * R / A
        return BaseAmount(result)
    }
    
    public static func getValueOfRuneInAsset(inputRune: BaseAmount, pool: PoolData) -> BaseAmount {
        // formula: ((r * A) / R) => A per R ($perRune)
        let r = inputRune.amount
        let R = pool.runeBalance.amount
        let A = pool.assetBalance.amount
        let result = r * A / R
        return BaseAmount(result)
    }
    
    public static func getDoubleSwapOutput(inputAmount: BaseAmount, pool1: PoolData, pool2: PoolData) -> BaseAmount  {
        // formula: getSwapOutput(pool1) => getSwapOutput(pool2)
        let r = getSwapOutput(inputAmount: inputAmount, pool: pool1, toRune: true)
        let output = getSwapOutput(inputAmount: r, pool: pool2, toRune: false)
        return output
    }
    
    public static func getDoubleSwapOutputWithFee(
        inputAmount: BaseAmount,
        pool1: PoolData,
        pool2: PoolData,
        transactionFee: BaseAmount = AssetAmount(1).baseAmount
    ) -> BaseAmount {
        // formula: (getSwapOutput(pool1) => getSwapOutput(pool2)) - runeFee
        let r = getSwapOutput(inputAmount: inputAmount, pool: pool1, toRune: true)
        let output = getSwapOutput(inputAmount: r, pool: pool2, toRune: false)
        let poolAfterTransaction = PoolData(
            assetBalance: BaseAmount(pool2.assetBalance.amount - output.amount), // subtract input amount from pool
            runeBalance: BaseAmount(pool2.runeBalance.amount + r.amount) // add RUNE output amount to pool
        )
        
        let runeFee = getValueOfRuneInAsset(inputRune: transactionFee, pool: poolAfterTransaction) // asset(oneRune)
        let result = output.amount - runeFee.amount // remove asset(oneRune)
        return BaseAmount(result)
    }
    
    public static func getDoubleSwapInput(pool1: PoolData, pool2: PoolData, outputAmount: BaseAmount) -> BaseAmount {
        // formula: getSwapInput(pool2) => getSwapInput(pool1)
        let y = getSwapInput(toRune: false, pool: pool2, outputAmount: outputAmount)
        let x = getSwapInput(toRune: true, pool: pool1, outputAmount: y)
        return x
    }

    
    /// Get slip, which is dependent on pool sizes. Output percentage 0.0 (0%) - 1.0 (100%)
    public static func getDoubleSwapSlip(inputAmount: BaseAmount, pool1: PoolData, pool2: PoolData) -> Decimal {
        // formula: getSwapSlip1(input1) + getSwapSlip2(getSwapOutput1 => input2)
        let swapSlip1 = getSwapSlip(inputAmount: inputAmount, pool: pool1, toRune: true)
        let r = getSwapOutput(inputAmount: inputAmount, pool: pool1, toRune: true)
        let swapSlip2 = getSwapSlip(inputAmount: r, pool: pool2, toRune: false)
        let result = swapSlip1 + swapSlip2
        return result
    }
    
    public static func getDoubleSwapFee(inputAmount: BaseAmount, pool1: PoolData, pool2: PoolData) -> BaseAmount {
        // formula: getSwapFee1 + getSwapFee2
        let fee1 = getSwapFee(inputAmount: inputAmount, pool: pool1, toRune: true)
        let r = getSwapOutput(inputAmount: inputAmount, pool: pool1, toRune: true)
        let fee2 = getSwapFee(inputAmount: r, pool: pool2, toRune: false)
        let fee1Asset = getValueOfRuneInAsset(inputRune: fee1, pool: pool2)
        let result = fee2.amount + fee1Asset.amount
        return BaseAmount(result)
    }

    public static func getValueOfAsset1InAsset2(inputAsset: BaseAmount, pool1: PoolData, pool2: PoolData) -> BaseAmount {
        // formula: (A2 / R) * (R / A1) => A2/A1 => A2 per A1 ($ per Asset)
        let oneAsset = AssetAmount(1).baseAmount
        // Note: All calculation needs to be done in `AssetAmount` (not `BaseAmount`)
        let A2perR = getValueOfRuneInAsset(inputRune: oneAsset, pool: pool2).assetAmount
        let RperA1 = getValueOfAssetInRune(inputAsset: inputAsset, pool: pool1).assetAmount
        let result = A2perR.amount * RperA1.amount
        // transform result back from `AssetAmount` into `BaseAmount`
        return AssetAmount(result).baseAmount
    }
}

extension Thorchain {
    public struct UnitData {
        public init(stakeUnits: BaseAmount, totalUnits: BaseAmount) {
            self.stakeUnits = stakeUnits
            self.totalUnits = totalUnits
        }
        public let stakeUnits : BaseAmount
        public let totalUnits : BaseAmount
    }
    public struct StakeData {
        public init(asset: BaseAmount, rune: BaseAmount) {
            self.asset = asset
            self.rune = rune
        }
        public let asset : BaseAmount
        public let rune : BaseAmount
    }
    
    public struct PoolData {
        public init(assetBalance: BaseAmount, runeBalance: BaseAmount) {
            self.assetBalance = assetBalance
            self.runeBalance = runeBalance
        }
      public let assetBalance: BaseAmount
      public let runeBalance: BaseAmount
    }
}
