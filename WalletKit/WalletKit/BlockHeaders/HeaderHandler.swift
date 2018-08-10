import Foundation
import RealmSwift

class HeaderHandler {
    enum HandleError: Error {
        case emptyHeaders
    }

    let realmFactory: RealmFactory
    let factory: Factory
    let validator: BlockValidator
    let saver: BlockSaver
    let network: NetworkProtocol

    init(realmFactory: RealmFactory, factory: Factory, validator: BlockValidator, saver: BlockSaver, configuration: Configuration) {
        self.realmFactory = realmFactory
        self.factory = factory
        self.validator = validator
        self.saver = saver
        self.network = configuration.network
    }

    func handle(headers: [BlockHeader]) throws {
        guard !headers.isEmpty else {
            throw HandleError.emptyHeaders
        }

        let realm = realmFactory.realm

        let blockInChain = realm.objects(Block.self).filter("previousBlock != nil").sorted(byKeyPath: "height")
        let initialBlock = blockInChain.last ?? network.checkpointBlock


        var newBlocks = [Block]()
        var previousBlock = initialBlock

        for header in headers {
            let block = factory.block(withHeader: header, previousBlock: previousBlock)
            newBlocks.append(block)

            previousBlock = block
        }

        var validBlocks = [Block]()

        var validationError: Error?

        do {
            for newBlock in newBlocks {
                try validator.validate(block: newBlock)
                validBlocks.append(newBlock)
            }
        } catch {
            validationError = error
        }

        if !validBlocks.isEmpty {
            try saver.create(blocks: validBlocks)
        }

        if let validationError = validationError {
            throw validationError
        }
    }

}
