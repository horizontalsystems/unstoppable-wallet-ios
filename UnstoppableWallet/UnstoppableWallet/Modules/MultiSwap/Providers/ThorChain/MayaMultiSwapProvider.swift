class MayaMultiSwapProvider: BaseThorChainMultiSwapProvider {
    override var baseUrl: String {
        "https://mayanode.mayachain.info/mayachain"
    }

    override var id: String {
        "mayachain"
    }

    override var name: String {
        "Maya Protocol"
    }

    override var icon: String {
        "maya_32"
    }

    override var affiliate: String? {
        AppConfig.mayaAffiliate
    }

    override var affiliateBps: Int? {
        AppConfig.mayaAffiliateBps
    }
}
