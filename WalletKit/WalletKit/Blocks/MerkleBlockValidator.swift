import Foundation

class MerkleBlockValidator {

    enum ValidationError: Error {
        case wrongMerkleRoot
        case noTransactions
        case tooManyTransactions
        case moreHashesThanTransactions
        case matchedBitsFewerThanHashes
        case unnecessaryBits
        case notEnoughBits
        case notEnoughHashes
        case duplicatedLeftOrRightBranches
    }

    static let MAX_BLOCK_SIZE: UInt32 = 1000000
    static let bitMask: [UInt8] = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80]

    func validateAndGetTxHashes(message: MerkleBlockMessage) throws -> [Data] {
        var matchedTxIds = [Data]()
        let merkleRoot = try getMerkleRootAndExtractTxids(message: message, matchedTxIds: &matchedTxIds)

        guard merkleRoot == message.blockHeader.merkleRoot else {
            throw ValidationError.wrongMerkleRoot
        }

        return matchedTxIds
    }


    /**
     * Extracts tx hashes that are in this merkle tree
     * and returns the merkle root of this tree.
     *
     * The returned root should be checked against the
     * merkle root contained in the block header for security.
     */
    private func getMerkleRootAndExtractTxids(message: MerkleBlockMessage, matchedTxIds: inout [Data]) throws -> Data {
        // An empty set will not work
        guard message.totalTransactions > 0 else {
            throw ValidationError.noTransactions
        }

        // check for excessively high numbers of transactions
        guard message.totalTransactions <= MerkleBlockValidator.MAX_BLOCK_SIZE / 60 else { // 60 is the lower bound for the size of a serialized CTransaction
            throw ValidationError.tooManyTransactions
        }

        // there can never be more hashes provided than one for every txid
        guard message.hashes.count <= message.totalTransactions else {
            throw ValidationError.moreHashesThanTransactions
        }
        // there must be at least one bit per node in the partial tree, and at least one node per hash
        guard message.flags.count * 8 >= message.hashes.count else {
            throw ValidationError.matchedBitsFewerThanHashes
        }

        // calculate height of tree
        var height: UInt32 = 0
        while getTreeWidth(transactionCount: message.totalTransactions, height: height) > 1 {
            height = height + 1
        }

        // traverse the partial tree
        let used = ValuesUsed()
        let merkleRoot = try recursiveExtractHashes(matchedTxIds: &matchedTxIds, height: height, pos: 0, used: used, message: message)

        // verify that all bits were consumed (except for the padding caused by serializing it as a byte sequence)
        guard (used.bitsUsed + 7) / 8 == message.flags.count &&
                      // verify that all hashes were consumed
                      used.hashesUsed == message.hashes.count else {
            throw ValidationError.unnecessaryBits
        }


        return merkleRoot
    }

    // recursive function that traverses tree nodes, consuming the bits and hashes produced by TraverseAndBuild.
    // it returns the hash of the respective node.
    private func recursiveExtractHashes(matchedTxIds: inout [Data], height: UInt32, pos: UInt32, used: ValuesUsed, message: MerkleBlockMessage) throws -> Data {
        guard used.bitsUsed < message.flags.count * 8 else {
            // overflowed the bits array - failure
            throw ValidationError.notEnoughBits
        }

        let parentOfMatch = checkBitLE(data: message.flags, index: used.bitsUsed)
        used.bitsUsed = used.bitsUsed + 1

        if (height == 0 || !parentOfMatch) {
            // if at height 0, or nothing interesting below, use stored hash and do not descend
            guard used.hashesUsed < message.hashes.count else {
                // overflowed the hash array - failure
                throw ValidationError.notEnoughHashes
            }

            let hash = message.hashes[used.hashesUsed]
            used.hashesUsed += 1
            if height == 0 && parentOfMatch {          // in case of height 0, we have a matched txid
                matchedTxIds.append(hash)
            }

            return hash
        } else {
            // otherwise, descend into the subtrees to extract matched txids and hashes
            let left = try recursiveExtractHashes(matchedTxIds: &matchedTxIds, height: height - 1, pos: pos * 2, used: used, message: message)
            var right = Data()

            if pos * 2 + 1 < getTreeWidth(transactionCount: message.totalTransactions, height: height - 1) {
                right = try recursiveExtractHashes(matchedTxIds: &matchedTxIds, height: height - 1, pos: pos * 2 + 1, used: used, message: message)
                guard left != right else {
                    throw ValidationError.duplicatedLeftOrRightBranches
                }
            } else {
                right = left
            }

            // and combine them before returning
            return combineLeftRight(left: left, right: right)
        }
    }

    private func combineLeftRight(left: Data, right: Data) -> Data {
        var result = Data()
        result.append(Data(left))
        result.append(Data(right))

        let hash = Crypto.sha256sha256(result)

        return Data(hash)
    }

    // helper function to efficiently calculate the number of nodes at given height in the merkle tree
    private func getTreeWidth(transactionCount: UInt32, height: UInt32) -> UInt32 {
        return (transactionCount + (1 << height) - 1) >> height
    }


    // Checks if the given bit is set in data, using little endian
    private func checkBitLE(data: [UInt8], index: Int) -> Bool {
        return (data[Int(index >> 3)] & MerkleBlockValidator.bitMask[Int(7 & index)]) != 0
    }

    private class ValuesUsed {
        var bitsUsed: Int = 0
        var hashesUsed: Int = 0
    }

}
