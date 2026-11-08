# Staff floor plan and table ordering

The staff screen now reads restaurant data and writes through the backend. Table
and order repositories never substitute mock data for an empty response or failure.
Deploy the backend changes together with the Flutter app.

## API contract

| Action | Endpoint |
| --- | --- |
| Floors | `GET /api/layout/floors` |
| Tables, status, deposit and geometry | `GET /api/restaurant-tables` |
| Manual table state | `PATCH /api/restaurant-tables/{id}?status=...` |
| Current serving order | `GET /api/orders/tables/{id}/active` |
| Open a table / send additional dishes | `POST /api/orders/tables/{id}/details` |
| Read the server's provisional bill | `GET /api/orders/{id}/checkout` |
| Kitchen tickets | `GET /api/orders/kitchen` |

The details request contains `expectedOrderId` (null when no active order was
loaded) and `items: [{itemId OR comboId, quantity, note}]`. The server locks the
table and rejects a changed session, duplicate active orders, an unavailable
table, unavailable products and reservations that have not checked in.

An available walk-in table receives a new order. A checked-in reservation without
an order gets its own reservation order. Otherwise the exact active order is used.
Each submission creates fresh PENDING tickets, preserving already-cooking dishes.
The server calculates prices; no client amount is submitted.

Mutations are limited to STAFF/ADMIN. Manual status changes cannot occupy a table
without an order/check-in or clear a table with a serving order, checked-in guest,
or overlapping live reservation. Internal reservation/payment state transitions
continue through the separate table-state service.

## Mobile behavior

- Real floor names, status/area filters, grid and pan/zoom geometry by area.
- Loading, empty, error and retry states, plus pull-to-refresh.
- Multiple dishes/combos, quantities and kitchen notes in one submission.
- Submission stays open and disabled until the server confirms; no optimistic
  success. An ambiguous timeout blocks resubmission in that sheet and asks staff
  to check the actual order/kitchen before placing another request.
- The old fixed-price payment dialog is replaced by a server-backed provisional
  bill. This feature does not implement settlement; the cashier must confirm
  payment through the payment workflow before completing the order.
- Check-in/cancellation opens reservation management, rather than changing a table
  flag to simulate check-in.
- Android debug builds allow HTTP for an emulator/LAN development server. Release
  API deployments should use HTTPS. Set the API URL in server settings, including
  `/api/`; `10.0.2.2` is the Android emulator default, not a physical phone address.

## Verification

Automated tests cover request/response contracts, empty/error handling, server-only
table state changes, session mismatches, reservation ownership of the serving
session, product availability, staff authorization, fresh kitchen tickets,
quantity/notes, double taps, timeout handling and a phone-sized grid/map.
Smoke tests now use deterministic API/repository fixtures instead of real network
requests; attendance scrollbars have explicit controllers for those smoke tests.

Run `flutter test`, `flutter analyze --no-fatal-infos --no-fatal-warnings`, and
`mvn test` from `backend/` (Java 21).

Before demoing against a real database/device:

1. Start the updated backend, sign in as STAFF and refresh the floor plan.
2. Open an available table; send a dish and a combo with quantity and notes.
3. Verify the persisted order/table after reload and the new PENDING KDS tickets.
4. Add a dish already cooking; verify the existing ticket is unchanged.
5. Verify a reserved table needs check-in and a checked-in no-food reservation
   receives an order linked to that reservation.
6. Try changing/clearing a table with an active order and changing the serving
   session from another client; verify the server rejects invalid operations.
7. Disconnect the network while submitting. Check the persisted order before
   manually retrying. Reopen the provisional bill and compare server totals.

No payment or email is sent by these tests. Live device/database verification is
separate from mocked automated tests. Kitchen updates on another device currently
require refresh; WebSocket subscriptions are outside this change.
