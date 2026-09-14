# 1.0.1

Bug fixes and robustness changes to the operation queue:
- `disconnect()` cancels whatever operation is executing or queued.
- Fixed read/subscribe stale data on failure, now surfacing the error.

# 1.0.0

BlueBreeze's first stable release. This version focuses on correctness of the operation queue,
full public API documentation, and a fully unit-tested, mockable CoreBluetooth layer — no
breaking changes to the public API since the beta 0.0.x releases.
