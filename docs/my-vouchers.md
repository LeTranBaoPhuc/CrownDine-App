# My vouchers

Branch: `feat/my-vouchers`, based on `feat/voucher-apply-payment`.

- `GET /api/user-vouchers/my` returns the signed-in customer's assigned vouchers
  that have remaining uses and have not expired. This is not the public catalog.
- `MyVoucherModel` maps the assignment DTO separately from the old mock/admin
  `VoucherModel`. Supports `PERCENTAGE` and `FIXED_AMOUNT`, nullable max discount,
  minimum order, expiration and usage limit. Null usage limit means unlimited.
- `myVouchersProvider` is auto-disposed and watches the authenticated user ID;
  account switching/logout cannot reuse the previous customer's wallet result.
- Profile wallet displays conditions and copies the exact code to Clipboard.
  Copy is acknowledged only when the platform call succeeds and keeps the wallet
  open. Loading, empty, error, retry and pull-to-refresh states use real API data.
- The checkout panel opens the same sheet in selection mode. Returning a code
  invokes the existing validate/apply/reload checkout flow. Being listed in the
  wallet does not guarantee eligibility for a specific order.
- Selection is disabled when there are no order items, while processing, or after
  a payment link is created. A real reservation ID must still be handed off from
  steps 1–3 as described in `step4-payment-integration.md`.
- Expiration is displayed in the local device timezone. Backend `expiredAt` uses
  LocalDateTime without offset, so the backend and client timezone convention must
  agree; final eligibility is always checked by the backend.

Validation: model/repository, account switch/logout, loading/empty/error retry,
Clipboard copy, and selection-to-checkout widget tests in `test/my_vouchers_test.dart`.
No backend or payment mutations are sent by tests.
