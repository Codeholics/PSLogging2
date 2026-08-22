# Send-Log Authentication Modernization Plan

## Decision

Keep SMTP as the default transport for compatibility with Windows PowerShell 5.1. Add secure SMTP configuration first, then introduce Microsoft Graph as the only built-in modern transport. Graph receives a caller-acquired bearer token; this module does not acquire, cache, or persist tokens.

Do not add a generic `Api` transport, third-party provider adapters, SMTP OAuth2, or a public `-SendScriptBlock` extension point in this work. Those features increase the supported API surface before the first transport contract is proven.

## Current State

`Send-Log` uses `System.Net.Mail.SmtpClient`, has a fixed 30-second timeout, and sends either an inline body or an attachment. It has no port, TLS, or credential controls. `SmtpClient` is still a practical Windows PowerShell 5.1 compatibility transport, but it is not a credible long-term path for OAuth-based Microsoft 365 delivery.

## Goals

- Preserve every existing `Send-Log` call without changing its behavior.
- Retain Windows PowerShell 5.1 support.
- Support authenticated, TLS-protected SMTP where an organization still provides it.
- Provide a Microsoft Graph path for Microsoft 365 environments that have disabled SMTP AUTH.
- Keep secrets out of log files, error messages, tests, and verbose output.
- Reuse the current redaction, inline/attachment selection, cleanup, and `-ThrowOnFailure` behavior across transports.

## Non-Goals

- Token acquisition, refresh, caching, or storage.
- SMTP OAuth2/XOAUTH2 support.
- SendGrid, Mailgun, or other provider-specific adapters.
- A generic REST transport or a public delegate/scriptblock transport API.
- Large Graph attachment upload sessions in the first Graph release.

## Public API

The existing SMTP parameters remain compatible. Add the following optional parameters:

```powershell
-Transport Smtp|Graph                 # Default: Smtp
-SmtpPort <int>                       # Default: 25
-UseSsl                               # SMTP only
-Credential <PSCredential>            # SMTP only
-AccessToken <string>                 # Graph only; never written to output
-GraphUserId <string>                 # Graph only; default: me
```

Parameter rules:

- `-SMTPServer` remains mandatory only for `-Transport Smtp`.
- `-AccessToken` is mandatory only for `-Transport Graph`.
- `-SmtpPort`, `-UseSsl`, and `-Credential` are invalid for Graph.
- `-GraphUserId` is invalid for SMTP. It must be either `me` or a user identifier accepted by Graph.
- `-EmailTo` keeps its current input compatibility: a comma-separated string or an array. Changing its declared type to `[string[]]` is a separate API decision.

Use PowerShell parameter sets so invalid combinations fail before a network call.

## Internal Design

1. `Send-Log` resolves and optionally redacts the log exactly once.
2. It creates one private payload object containing recipients, sender, subject, inline body or attachment path, and content metadata.
3. It invokes a private `Send-LogSmtp` or `Send-LogGraph` helper.
4. Both helpers return `$true` or throw. The public function remains the single owner of error formatting, temporary-file cleanup, `$false` returns, and `-ThrowOnFailure` behavior.

This is an internal dispatch design, not a public transport plugin contract. It keeps the initial scope small while leaving room to add an adapter later.

## Delivery Phases

### Phase 1: Secure SMTP configuration

Implement the SMTP parameters above, set `SmtpClient.Port`, `EnableSsl`, and `Credentials` only when supplied, and preserve the existing timeout and disposal guarantees.

Acceptance criteria:

- Existing SMTP tests pass unchanged.
- New Pester tests verify default port behavior, port/TLS assignment, credential assignment, invalid parameter combinations, and that credential data is not emitted.
- The suite passes in `powershell.exe` (Windows PowerShell 5.1).

### Phase 2: Graph transport for inline logs

Implement `Send-LogGraph` using `Invoke-RestMethod` and `POST https://graph.microsoft.com/v1.0/{me-or-users/{id}}/sendMail`. Use the Graph JSON message schema and send an inline text body. The caller supplies a valid access token with the appropriate `Mail.Send` permission.

Graph must reject attachment-mode sends in this phase with a clear, non-secret error. Direct Graph attachments have small-request limitations and upload sessions require draft-message lifecycle handling; implement that separately instead of silently changing delivery behavior.

Acceptance criteria:

- Pester mocks assert endpoint, authorization header, recipients, subject, and sanitized inline body.
- Missing tokens and Graph HTTP failures return `$false` by default and throw with `-ThrowOnFailure`.
- Tests prove the access token is absent from emitted error messages.
- The implementation works under Windows PowerShell 5.1 with `Invoke-RestMethod`.

### Phase 3: Graph attachments (separate decision)

Decide between MIME submission and the Graph draft-message plus upload-session workflow. Design and test the full lifecycle, including cleanup of unsuccessful drafts, before enabling `-MaxInlineSizeMB` attachment behavior for Graph. Do not begin this phase until a real Microsoft 365 test tenant and opt-in integration-test secret flow are available.

## Testing and Validation

- Keep all current SMTP unit tests and extend them for Phase 1.
- Mock `Invoke-RestMethod` for Graph unit tests; no live network calls in the normal Pester suite.
- Add opt-in integration tests only when all required environment variables are present. They must be skipped otherwise and never print secrets.
- Run the full suite with `powershell.exe`, not only `pwsh`.

## Security Requirements

- Never include `-Credential`, `-AccessToken`, authorization headers, or raw request bodies in errors, verbose output, or logs.
- Use least-privilege Graph permissions and document the required delegated or application permission model separately.
- Document that `SecureString` protects local handling, not a bearer token sent over the network; TLS is required for SMTP credentials and HTTPS is required for Graph.

## Completion Definition for This Plan Item

This planning item is complete when this document is approved and `Docs/plans.md` links to it. Implementation completion requires Phase 1 and Phase 2 acceptance criteria; Phase 3 remains a separately planned enhancement.

## Recommended Next Implementation Step

Implement Phase 1 only: secure SMTP configuration with parameter sets and Pester coverage. It is backward-compatible, useful for current deployments, and creates the dispatch boundary that Graph will use without committing to an unstable extension API.
