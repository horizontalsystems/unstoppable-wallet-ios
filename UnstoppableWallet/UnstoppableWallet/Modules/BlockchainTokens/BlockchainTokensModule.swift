struct BlockchainTokensModule {

    static func module() -> (BlockchainTokensService, BlockchainTokensView) {
        let service = BlockchainTokensService()
        let viewModel = BlockchainTokensViewModel(service: service)
        let view = BlockchainTokensView(viewModel: viewModel)

        return (service, view)
    }

}
