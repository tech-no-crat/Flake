# Incident: Sunshine Streaming Disconnects Every ~20 Seconds

**Date:** 2026-04-26  
**System:** NixOS 26.05 (Yarara), kernel 7.0.0, `nixos` host  
**Service:** Sunshine game streaming → Moonlight on Samsung Galaxy S24 Ultra  
**Status:** Resolved

---

## Background

The goal was to stream games from the NixOS desktop (Sunshine server) to a mobile device running
Moonlight. This had worked before, but after a system rebuild things were broken in multiple ways.

---

## Issue 1: Autologin Not Working

**Symptom:** After reboot the machine sat at the GDM greeter instead of logging in automatically.
Sunshine requires an active graphical session to capture the display, so this meant streaming would
never start cleanly on boot.

**Cause:** The NixOS config simply never had autologin configured.

**Fix:** Added to `modules/gnome.nix`:

```nix
services.displayManager.autoLogin = {
  enable = true;
  user = "shyam";
};
```

---

## Issue 2: Sunshine Starting Twice and Crashing

**Symptom:** Sunshine would crash shortly after boot. Investigation revealed it was being started
twice — once in the GDM greeter session (as user `gdm`) and once in the real user session. The
second start saw the first instance's lock files and died.

**Cause:** A known NixOS bug where the Sunshine systemd service unit lacked a `ConditionUser`
guard, causing it to start in the GDM greeter session.

**Workaround applied:** Added `ConditionUser = "shyam"` to the service unit via an override.

**Final fix:** Once autologin (Issue 1) was enabled, GDM's greeter session is never created — the
system goes straight to the user session. The `ConditionUser` workaround became redundant and was
removed. The upstream NixOS bug was filed at:
https://github.com/NixOS/nixpkgs/issues/513458

---

## Issue 3: Streaming Disconnects Every ~20 Seconds

This was the main event, and it took a while to track down.

### Symptoms

- Moonlight would connect successfully and streaming would begin
- After approximately 20 seconds the stream would drop
- Moonlight would immediately reconnect, stream for another ~20 seconds, drop again — forever
- Sunshine server logs showed a clean `CLIENT CONNECTED` followed by `CLIENT DISCONNECTED` with
  nothing in between. The server was completely innocent.

### Things That Were Ruled Out

**Tailscale:** Disabled with `sudo tailscale down`. Problem persisted. Not the cause.

**Router DoS / flood protection:** The router had AI-protection features that could potentially
rate-limit or block a high-bandwidth UDP stream. Disabled. Problem persisted. Not the cause.

**Sunshine configuration:** Logs were clean. No errors, no crashes, no re-starts during the
disconnect window.

**NixOS configuration changes:** Recent commits had added `uinput` to initrd and udev rules for
Sunshine. All were already present and correct.

### Getting the Router Logs

The next step was to look at the router side. The Asus TUF AX6000 can export a syslog file
directly from its web UI under **Administration → System Log**.

A netcat UDP listener was attempted first:

```bash
nix run nixpkgs#netcat -- -ulk 5140 | tee /tmp/router-syslog.txt
```

The router was pointed at the machine's IP on port 5140, but **no packets arrived** — the router
appeared to silently drop or not send UDP syslog despite the setting being saved. The live capture
approach did not work.

The workaround was to download the syslog directly from the router UI
(**Administration → System Log → Save**) immediately after reproducing the disconnect.

### What the Log Showed

The log revealed the Moonlight client's MAC address — `2a:77:fc:7f:21:52` — repeatedly cycling
through the following pattern every ~20 seconds:

```
Del Sta:2a:77:fc:7f:21:52           # disconnected from rax0 (5GHz)
New Sta:2a:77:fc:7f:21:52 on ra0    # connected to ra0 (2.4GHz)
New Sta:2a:77:fc:7f:21:52 on rax0   # connected to rax0 (5GHz) again
AUTH - receive DE-AUTH(seq-XXXX) from 2a:77:fc:7f:21:52, reason=1
# ... 20 seconds of silence ...
# repeat
```

`reason=1` means the **client** sent the deauth frame — it was voluntarily disconnecting from the
router, not being kicked. The sequence number on the deauth frame also incremented normally,
confirming these were real frames from the client, not a firmware anomaly.

The `2a` prefix on the MAC (`2a:77:fc:7f:21:52`) is significant: the locally-administered bit is
set, meaning the device is using a **randomized/private MAC address**. This is normal modern
behaviour but it means the router cannot build a stable roaming history for the device.

### First Theory: Smart Connect Band-Steering

The Asus "Smart Connect" feature uses a single SSID for all bands and steers clients between
2.4 GHz and 5 GHz automatically. With a randomized MAC and two radios both seeing the same client
simultaneously (`ra0` and `rax0`), it looked like a band-steering death spiral: the router moves
the client, the client disagrees, they fight forever.

**Smart Connect was disabled.** Separate SSIDs were configured for each band. The Moonlight device
was connected directly to the 5 GHz SSID.

**Result:** Still disconnecting. Same 20-second cycle.

### The Real Cause: 802.11k Roaming Assistant / Firmware Bug

Looking at the log more carefully, two lines appeared immediately after every successful
reconnection:

```
RRM_PeerNeighborReqAction() 880: snprintf error!
```

This is the router sending an **802.11k Radio Resource Management (RRM) Neighbor Report** to the
client right after it connects. 802.11k is the protocol where an AP proactively tells a client
"here are nearby APs you could roam to." The `snprintf error` indicates the router's firmware is
constructing this frame **incorrectly** — it's a bug in the Asus TUF AX6000 firmware.

The client receives a malformed 802.11k neighbor report, interprets it as a roaming suggestion,
sends a deauth (reason=1: "leaving the current BSS"), immediately reconnects, receives another
malformed neighbor report, and the cycle repeats every ~20 seconds indefinitely.

**Fix:** In the Asus router UI, **Wireless → Professional**, set **Roaming assistant → Disable**
on **both** the 2.4 GHz and 5 GHz band tabs. This stops the router from sending 802.11k RRM
frames entirely.

**Result:** Disconnects stopped. Streaming stable.

---

## Summary of Fixes

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| No autologin | Missing config | `services.displayManager.autoLogin` in `modules/gnome.nix` |
| Sunshine crashes on boot | Started in GDM greeter session (nixpkgs bug) | Fixed by autologin removing greeter session entirely |
| Streaming disconnects every ~20s | Asus firmware bug: malformed 802.11k RRM neighbor report frames sent to client after every connect, triggering client-initiated deauth loop | Disable **Roaming assistant** in Wireless → Professional on the router (both bands) |

---

## Diagnostic Commands Used

```bash
# Capture router syslog in real-time (NOTE: this did not work on the Asus TUF AX6000
# — UDP forwarding silently failed. Use the router UI instead.)
nix run nixpkgs#netcat -- -ulk 5140 | tee /tmp/router-syslog.txt

# Better: download syslog from router UI
# Administration → System Log → Save

# Watch Sunshine logs during a streaming session
journalctl -u sunshine -f

# Check if Sunshine is running with correct user/PID
systemctl status sunshine
```

---

## Notes for the Future

- **If streaming disconnects start again:** Check the router syslog first. The `RRM_PeerNeighborReqAction snprintf error` line is the smoking gun. Download it from **Administration → System Log → Save** in the Asus UI — the live UDP forwarding to netcat did not work.
- **Asus firmware updates** may fix or re-introduce this bug. After a firmware update, re-check the Roaming assistant setting — it may revert to enabled.
- **MAC randomization** (`2a:xx` prefix) makes router-side diagnosis harder since the device doesn't appear under its OUI in device lists. Check for locally-administered bit (second nibble of first octet: `2`, `6`, `a`, or `e`).
- The **nixpkgs bug** for Sunshine double-starting is tracked at https://github.com/NixOS/nixpkgs/issues/513458 — once fixed upstream, the `package = pkgs-unstable.sunshine` pin may no longer be necessary.
