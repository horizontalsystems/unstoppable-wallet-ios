import ReownWalletKit

struct WCProposalItem {
    let proposal: Session.Proposal
    let context: VerifyContext?
    let verifyState: WCVerifyState
    let blockchainProposals: [WCBlockchainProposal]
}
