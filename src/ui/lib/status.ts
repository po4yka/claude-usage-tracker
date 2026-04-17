import { statusByPlacement, type StatusPlacement, type StatusKind } from '../state/store';

const timers: Partial<Record<StatusPlacement, number>> = {};

function cancelTimer(placement: StatusPlacement): void {
  const t = timers[placement];
  if (t != null) {
    clearTimeout(t);
    delete timers[placement];
  }
}

export function setStatus(
  placement: StatusPlacement,
  kind: StatusKind,
  message: string,
  autoDismissMs?: number,
): void {
  statusByPlacement.value = { ...statusByPlacement.value, [placement]: { kind, message } };
  cancelTimer(placement);
  if (autoDismissMs && autoDismissMs > 0) {
    timers[placement] = window.setTimeout(() => clearStatus(placement), autoDismissMs);
  }
}

export function clearStatus(placement: StatusPlacement): void {
  statusByPlacement.value = { ...statusByPlacement.value, [placement]: null };
  cancelTimer(placement);
}
