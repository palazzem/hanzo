#!/usr/bin/env bash
set -euo pipefail

# Configures per-display color profile, color/power tradeoff, adaptive sync
# (VRR) policy, auto-rotate policy, and scale for every connected+enabled
# output, via kscreen-doctor.
#
# Applies live (no logout/login) and persists to
# ~/.config/kwinoutputconfig.json. Idempotent: safe to re-run.
#
# Config:
#   COLOR_PROFILE_SOURCE=EDID            (default) sRGB|ICC|EDID
#   COLOR_POWER_TRADEOFF=preferAccuracy  (default) preferEfficiency|preferAccuracy
#   VRR_POLICY=automatic                 (default) never|always|automatic
#   SCALE=1.6                            (default) e.g. 1.6 = 160%
#   AUTO_ROTATE_POLICY=always            (default) never|inTabletMode|always
#   OUTPUT_NAME=                         (default: empty = all connected+enabled outputs)

COLOR_PROFILE_SOURCE="${COLOR_PROFILE_SOURCE:-EDID}"
COLOR_POWER_TRADEOFF="${COLOR_POWER_TRADEOFF:-preferAccuracy}"
VRR_POLICY="${VRR_POLICY:-automatic}"
SCALE="${SCALE:-1.6}"
AUTO_ROTATE_POLICY="${AUTO_ROTATE_POLICY:-always}"
export OUTPUT_NAME="${OUTPUT_NAME:-}"

mapfile -t outputs < <(kscreen-doctor -j | python3 -c "
import json, sys, os
d = json.load(sys.stdin)
only = os.environ.get('OUTPUT_NAME', '')
for o in d['outputs']:
    if not (o['connected'] and o['enabled']):
        continue
    if only and o['name'] != only:
        continue
    print(o['name'])
")

if [ "${#outputs[@]}" -eq 0 ]; then
  echo "No connected+enabled output found." >&2
  exit 1
fi

args=()
for name in "${outputs[@]}"; do
  echo "Configuring display: $name"
  args+=(
    "output.${name}.colorProfileSource.${COLOR_PROFILE_SOURCE}"
    "output.${name}.colorPowerTradeoff.${COLOR_POWER_TRADEOFF}"
    "output.${name}.vrrpolicy.${VRR_POLICY}"
    "output.${name}.scale.${SCALE}"
    "output.${name}.autoRotatePolicy.${AUTO_ROTATE_POLICY}"
  )
done

kscreen-doctor "${args[@]}"
