/// What a chain's pre-send handler hands to its send handler through `SendData.chain`.
/// A value type owned by the chain; it carries no key material.
public protocol ChainSendPayload {}
