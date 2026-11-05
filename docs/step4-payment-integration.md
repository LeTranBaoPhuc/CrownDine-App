# Step 4 payment integration

Step 4 uses real API responses only. It does not create reservations or synchronize
items; these remain the responsibility of steps 1–3. The old mock QR/success dialog
has been removed. Until the upstream integration publishes a real ID, step 4 shows
a waiting message and cannot collect payment.

## Handoff from reservation/food implementation

Import `providers/reservation_checkout_provider.dart`. Keep the checkout binding
null while creating/updating a reservation or synchronizing any cart changes:

```dart
ref.read(checkoutReservationIdProvider.notifier).state = null;
// Create/resume the real backend reservation, then await ALL add/update/remove
// item requests. Do not publish an ID from the mock fallback repository.
ref.read(checkoutReservationIdProvider.notifier).state = reservationId;
ref.read(reservationProvider.notifier).setStep(4);
```

The reservation screen watches this auto-disposed binding throughout all steps.
Invalidate it before editing upstream data, on logout, and before a new booking.
Step 4 gets `orderId`, reservation code, status, expiry and all monetary values
from `GET reservations/{id}/checkout`; callers must not calculate these locally.
No-food bookings can pay the table deposit but cannot apply vouchers.

Once a payment link exists, do not change the reservation/cart or voucher while
that link remains payable. The screen disables previous-step navigation then.

## API flow

- GET `reservations/{id}/checkout`
- POST `vouchers/validate` with `{orderId, code}`, then POST
  `orders/{orderId}/voucher/apply` with `{code}` and reload checkout
- DELETE `orders/{orderId}/voucher`, then reload checkout
- POST `payments/create` with `{reservationCode, method: "PAYOS"}` (no client amount)
- Open the returned HTTPS URL in WebView
- Intercept the return/cancel paths and use `orderCode` to GET
  `payments/code/{code}`. Only a backend `SUCCESS` for this reservation with target
  `RESERVATION` renders success. Redirect status alone is never trusted.

Backend currently rejects CASH for reservation deposits. UI offers PAYOS only.
The backend quote is refreshed before link creation; changes require review and
another tap. Reopening PayOS within the current screen reuses the same link.
Status checks are sequential and bounded (10 attempts, 2 seconds apart), with a
manual retry for webhook delays. No real payment is sent by tests.

## Callback configuration

Defaults match the existing web frontend:
- `/thanh-toan/thanh-cong`
- `/thanh-toan/that-bai`

If backend `payos.return-url` / `payos.cancel-url` uses different paths, provide
`--dart-define=PAYOS_SUCCESS_PATH=/...` and `--dart-define=PAYOS_CANCEL_PATH=/...`.
The path is intercepted before loading the web frontend (including localhost).
The query must contain the numeric PayOS `orderCode`. The mobile UI supports QR
and bank transfer instructions in WebView; bank-app custom scheme redirects are
not launched automatically.

## Backend gaps / acceptance checks

Before production, fix the ownership/admin authorization and concurrent voucher
usage issues identified in the backend review. Checkout doesn't return voucher
code, so a pre-existing discount can be shown/removed without displaying its code.
The API returns only a link, without payment code at creation or an endpoint to
resume a pending payment by reservation. The current link is retained while this
screen is mounted, not across process death. Backend idempotent create/resume plus
persisted recovery is needed before guaranteeing safe retries after app restart
or an ambiguous create-payment timeout. The current session blocks another create
after an ambiguous timeout; do not infer failed payment from a timeout.

Acceptance with the upstream integration and configured PayOS webhook:
1. Real no-food reservation: checkout shows table deposit and voucher is disabled.
2. Real reservation with items: apply/remove code and totals agree with checkout.
3. Redirect says PAID but backend says PENDING: show awaiting confirmation.
4. Closing PayOS: no success; reopening uses the same link.
5. Backend confirms SUCCESS for this reservation: show paid amount and finish.
6. Foreign payment code, expired booking, network failure: no false success.
