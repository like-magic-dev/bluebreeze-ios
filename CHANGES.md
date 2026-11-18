# 1.1.0

**Breaking changes**
- Every observable property is now a `BBObservable` instead of a `CurrentValueSubject`:
  - `value` returns the current value, as before.
  - `values` emits the current value and then new values. Use it if you need replay of the current
    value on subscription.
  - `updates` emits only new values. Use it if you only want to subscribe to future updates.
- Removed `BBCharacteristic.notifications`, use `data.updates` instead.
- Removed the `CurrentValueSubject.updates` extension.

# 1.0.2

- Add `notifications` property to `BBCharacteristic` as a pure data stream without replay.

# 1.0.1

Bug fixes and robustness changes to the operation queue:
- `disconnect()` cancels whatever operation is executing or queued.
- Fixed read/subscribe stale data on failure, now surfacing the error.

# 1.0.0

BlueBreeze's first stable release. This version focuses on correctness of the operation queue,
full public API documentation, and a fully unit-tested, mockable CoreBluetooth layer — no
breaking changes to the public API since the beta 0.0.x releases.
