# TelemetryDeck retention control

Kindling uses a three-month live query window for routine product analysis and
a maximum total analytics retention period of 12 months.

TelemetryDeck documents that events outside a plan's live query window can
remain in cold storage. It also documents that one-time or automatic deletion
must be arranged by contacting TelemetryDeck.

## Required provider configuration

- Automatically delete production and test events when they reach 12 months.
- Apply deletion to queryable storage, cold storage, exports, and recoverable
  copies controlled by TelemetryDeck.
- Delete any events already older than 12 months when the control is enabled.
- Keep the live query window at three months.
- Confirm the effective date, scope, and any plan or pricing impact in writing.

Provider contact: `support@telemetrydeck.com`

Kindling contact: `hello@maskedsyntax.com`

## Request status

The automatic-deletion request was sent to TelemetryDeck support on August 27,
2026 from `aftaab@maskedsyntax.com`. Provider confirmation is pending.

## Release evidence

Before publishing the website or submitting the app, retain TelemetryDeck's
written confirmation with the release records. Reconfirm the setting annually
and whenever the TelemetryDeck plan, organization, or app configuration changes.

References:

- <https://telemetrydeck.com/use-case/architecture-security/>
- <https://telemetrydeck.com/faq/>
- <https://telemetrydeck.com/contact/>
