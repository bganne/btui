#!/usr/bin/env bash
# Lint + unit tests for btui. Usage: ./test.sh
set -u
cd "$(dirname "$0")" || exit 1
fail=0
ok()  { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }
# check NAME CMD…  → ok/FAIL depending on CMD's exit status
check() { local n=$1; shift; if "$@"; then ok "$n"; else bad "$n"; fi; }
eq()  { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1: expected [$3], got [$2]"; fi; }

# ---- lint ----
if command -v shellcheck >/dev/null; then
  check shellcheck shellcheck -x btui test.sh
else
  bad "shellcheck (not installed)"
fi
check "bash -n" bash -n btui

# ---- unit tests with a stubbed bluetoothctl ----
stub=$(mktemp -d); trap 'rm -rf "$stub"' EXIT
cat >"$stub/bluetoothctl" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  "devices Paired")    printf 'Device AA:AA:AA:AA:AA:01 Headset\nDevice AA:AA:AA:AA:AA:02 Speaker\n' ;;
  "devices Connected") printf 'Device AA:AA:AA:AA:AA:02 Speaker\n' ;;
  devices)             printf 'Device AA:AA:AA:AA:AA:01 Headset\nDevice AA:AA:AA:AA:AA:02 Speaker\nDevice BB:BB:BB:BB:BB:01 Far\nDevice BB:BB:BB:BB:BB:02 Near\nDevice CC:CC:CC:CC:CC:01 CC-CC-CC-CC-CC-01\n' ;;
  "info AA:AA:AA:AA:AA:01") printf '\tName: Headset\n\tIcon: audio-headset\n\tPaired: yes\n\tConnected: no\n\tBattery Percentage: 0x50 (80)\n' ;;
  "info AA:AA:AA:AA:AA:02") printf '\tName: Speaker\n\tIcon: audio-card\n\tPaired: yes\n\tConnected: yes\n' ;;
  "info BB:BB:BB:BB:BB:01") printf '\tName: Far\n\tIcon: phone\n\tRSSI: 0xffffffb0 (-80)\n' ;;
  "info BB:BB:BB:BB:BB:02") printf '\tName: Near\n\tRSSI: -55\n' ;;
  "info CC:CC:CC:CC:CC:01") printf '\tName: CC-CC-CC-CC-CC-01\n' ;;
  show) printf 'Controller 00:11:22:33:44:55 (public)\n\tAlias: laptop\n\tPowered: yes\n\tPowerState: on\n' ;;
esac
EOF
chmod +x "$stub/bluetoothctl"

(
  PATH="$stub:$PATH"
  # shellcheck source=btui
  . ./btui
  ok "source without starting UI"

  eq "bars -50"   "$(bars -50)"  "▂▄▆█"
  eq "bars -75"   "$(bars -75)"  "▂▄  "
  eq "bars empty" "$(bars '')"   "    "

  dev_info AA:AA:AA:AA:AA:01
  eq "dev_info name" "$D_NAME" Headset
  eq "dev_info type" "$D_TYPE" headset
  eq "dev_info batt" "$D_BATT" 80
  eq "dev_info conn" "$D_CONN" ""
  dev_info BB:BB:BB:BB:BB:01
  eq "dev_info rssi hex" "$D_RSSI" -80
  eq "dev_info type fallback" "$D_TYPE" phone
  dev_info BB:BB:BB:BB:BB:02
  eq "dev_info rssi plain" "$D_RSSI" -55
  eq "dev_info type default" "$D_TYPE" device

  eq "power_state" "$(power_state)" on
  check is_on is_on
  check "has Connected" has AA:AA:AA:AA:AA:02 Connected

  mapfile -t p < <(list_paired)
  eq "list_paired connected first" "${p[0]}" AA:AA:AA:AA:AA:02
  eq "list_paired count" "${#p[@]}" 4

  mapfile -t u < <(list_unpaired)
  eq "list_unpaired nearest first, unnamed skipped" "${u[0]} ${u[2]} ${#u[@]}" \
     "BB:BB:BB:BB:BB:02 BB:BB:BB:BB:BB:01 4"

  eq "count_new" "$(count_new)" 2
  exit "$fail"
) || fail=1

exit "$fail"
