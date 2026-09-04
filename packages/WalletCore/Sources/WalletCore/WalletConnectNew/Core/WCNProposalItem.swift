import ReownWalletKit

struct WCNProposalItem {
    let proposal: Session.Proposal
    let context: VerifyContext?
    let verifyState: WCNVerifyState
    let blockchainProposals: [WCNBlockchainProposal]
}
