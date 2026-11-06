# Reservation and payment flow

Steps 1–3 now create a real reservation and synchronize preordered items before
step 4 receives its backend reservation ID. The selected table is checked against
the live table list; the reservation API decides slot availability. Cart sync reads
the server first, uses absolute quantities for updates, and verifies the final cart.
A partial failure keeps the reservation ID so retry does not create another hold.
If creation times out without an ID, the screen stops retries and asks the customer
to check their history or contact the restaurant.

Step 4 reads all amounts and status from `GET reservations/{id}/checkout`.
No-food bookings can pay the table deposit but cannot apply vouchers. The history
screen can reopen checkout for a pending reservation.

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
another tap. Reopening PayOS reuses the saved link, including after app restart on the same device.
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

The backend should provide an idempotent create/resume payment API and a lookup by
reservation. The mobile app stores the payment intent before requesting a link and
blocks another create after an ambiguous timeout. The customer must contact the
restaurant if the request succeeded but the response was lost. This local hint is
scoped to the account and API URL; it is never evidence of successful payment.
Before production, review backend ownership/admin authorization and concurrent
voucher usage. Checkout does not return the applied voucher code, so a pre-existing
discount can be shown or removed without displaying its code.

1. A no-food reservation shows the table deposit and disables vouchers.
2. A reservation with items shows backend totals after apply/remove voucher.
3. A PayOS redirect alone does not mark the booking paid; backend `SUCCESS` does.
4. Closing and reopening PayOS reuses the saved link.
5. Foreign payment code, expired booking, and network failure show no false success.
6. Partial cart sync can retry without adding quantities twice.
