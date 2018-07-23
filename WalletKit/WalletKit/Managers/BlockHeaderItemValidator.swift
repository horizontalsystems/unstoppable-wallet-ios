import Foundation
import BigInt

class BlockHeaderItemValidator {
    static let shared = BlockHeaderItemValidator()

    enum HeaderValidatorError: Error {
        case noCheckpointBlock
    }

    static let maxTargetDifficulty: UInt32 = 0x1d00ffff                // Maximum difficulty.
    static let targetTimeSpan: Int = 14 * 24 * 60 * 60              // 2 weeks per difficulty cycle, on average.
    static let targetSpacing: Int = 10 * 60                         // 10 minutes per block.
    static let heightInterval = targetTimeSpan / targetSpacing

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func isValid(item: BlockHeaderItem, previousItem: BlockHeaderItem, previousHeight: Int) throws -> Bool {
        var equalDifficulty = item.bits == previousItem.bits
        if isDifficultyTransitionPoint(height: previousHeight) {
            let newDifficulty: UInt32
            do {
                newDifficulty = try difficultyAfter(item: item, height: previousHeight)
            } catch let error {
                throw error
            }
            equalDifficulty = newDifficulty == previousItem.bits
        }
        return item.prevBlock == Crypto.sha256sha256(previousItem.serialized()) && equalDifficulty
    }

    func isDifficultyTransitionPoint(height: Int) -> Bool {
        return (height + 1) % BlockHeaderItemValidator.heightInterval == 0
    }

    func difficultyAfter(item: BlockHeaderItem, height: Int) throws -> UInt32 {
        let realm = realmFactory.realm

        guard let lastBlock = realm.objects(Block.self).filter("height = %@", height - 2015).last else {
            throw HeaderValidatorError.noCheckpointBlock
        }
        let lastBlockItem = BlockHeaderItem.deserialize(byteStream: ByteStream(lastBlock.rawHeader))
        let timeSpan = limit(timeSpan: Int(item.timestamp - lastBlockItem.timestamp))

        var bigIntDifficulty = BlockHeaderItemValidator.decodeCompact(bits: item.bits)
        bigIntDifficulty *= BigInt(timeSpan)
        bigIntDifficulty /= BigInt(BlockHeaderItemValidator.targetTimeSpan)
        let newDifficulty = min(BlockHeaderItemValidator.encodeCompact(from: bigIntDifficulty), BlockHeaderItemValidator.maxTargetDifficulty)

        return UInt32(newDifficulty)
    }

    func limit(timeSpan: Int) -> Int {
        return min(max(timeSpan, BlockHeaderItemValidator.targetTimeSpan / 4), BlockHeaderItemValidator.targetTimeSpan * 4)
    }

/**
     * <p>The "compact" format is a representation of a whole number N using an unsigned 32 bit number similar to a
     * floating point format. The most significant 8 bits are the unsigned exponent of base 256. This exponent can
     * be thought of as "number of bytes of N". The lower 23 bits are the mantissa. Bit number 24 (0x800000) represents
     * the sign of N. Therefore, N = (-1^sign) * mantissa * 256^(exponent-3).</p>
     *6297032256704216602113604774641040999057504088462746055606272
     * <p>Satoshi's original implementation used BN_bn2mpi() and BN_mpi2bn(). MPI uses the most significant bit of the
     * first byte as sign. Thus 0x1234560000 is compact 0x05123456 and 0xc0de000000 is compact 0x0600c0de. Compact
     * 0x05c0de00 would be -0x40de000000.</p>
     *
     * <p>Bitcoin only uses this "compact" format for encoding difficulty targets, which are unsigned 256bit quantities.
     * Thus, all the complexities of the sign bit and using base 256 are probably an implementation accident.</p>
 */

    public static func decodeCompact(bits: UInt32) -> BigInt {
        let size = (bits >> 24) & 0xFF

        let negativeSign = (bits >> 23) & 0x0001 == 1

        let significantBytes = bits & 0x007FFFFF
        var bigInt = BigInt(significantBytes) * (negativeSign ? -1 : 1)
        if size > 3 {
            bigInt = bigInt << ((size - 3) * 8)
        }

        return bigInt
    }

    public static func encodeCompact(from bigInt: BigInt) -> UInt32 {
        var result: UInt32 = 0

        // make unsigned big int for get array of bytes
        let data = bigInt.magnitude.serialize()

        var byteArray = data.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: data.count))
        }

        if let firstByte = byteArray.first, firstByte > 0x7f {
            // add leading zero if first byte value use more 7 bits
            byteArray.insert(0x00, at: 0)
        }

        // add significant bytes to result
        for (i, byte) in byteArray.enumerated() {
            result = result << 8 + UInt32(byte)
            if i >= 2 {
                break
            }
        }

        // add counter to result
        result += UInt32(byteArray.count) << 24


        // add sign for first byte
        if bigInt.sign == .minus {
            result |= 0x800000
        }

        return result
    }

}
