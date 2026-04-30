# Legacy passkey-native AA

Files implementing the original P-256 / WebAuthn account-abstraction flow
(Phases 1-11, 2026-04-22 to 2026-04-29). Frozen 2026-04-30.

No new code instantiates these classes. Existing
`AccountType.passkeyOwned` records (zero in user DB after manual drain
2026-04-29) read through these code paths only until PR-A5 / PR-A6
remove the remaining call sites.

Discriminator after PR-A3 lands: `AccountType.PasskeyCurve == .secp256r1`.

## TODO-A

Delete this folder entirely when:

1. PR-A5 removes `SmartAccountPasskeyManager` from `CreateSmartAccountService`, AND
2. PR-A6 removes `Secp256r1VerificationFacet.dummySignature()` and
   `PasskeyUserOpSigner.sign(...)` from `AaSender`, AND
3. Strategic decision is made to drop passkey-native AA support
   (no migration via `SignatureMigrationFacet`).

## TODO-B

After TODO-A, prune `aa.sqlite` rows with
`implementationVersion = "barz_v1_0_0"`. Currently zero such rows.

## Reference

- Background: `docs/aa-reports/2026-04-29-secp256k1-pivot-and-xrp-research.md`
- Spec: `docs/superpowers/specs/2026-04-29-v1-secp256k1-aa-spec.md`
- Memory: `project_aa_v1_secp256k1_locked_decisions.md`
