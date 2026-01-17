# YubiKey-backed LUKS unlock (manual)

generated with chatgpt so verify before apply.

## Goal
Add a YubiKey-backed keyslot to an existing LUKS volume so the system can boot without typing the disk passphrase.

## Preconditions
- Existing LUKS-encrypted disk
- Working system boot
- Physical access
- A spare LUKS keyslot
- One YubiKey (no automation intended)

## How to do it

1. Verify free slots:
`cryptsetup luksDump /dev/<disk>`

2. Enroll YubiKey into a new slot:
`systemd-cryptenroll /dev/<disk> --fido2-device=auto`
- Keep your original passphrase slot untouched.

3. Test unlock manually:
`cryptsetup open /dev/<disk> test-unlock`
Touch the YubiKey when prompted.

4. Reboot and verify boot-time unlock works.

## Safety rules
- Never remove the password-based slot.
- Keep a live ISO available.
- If anything feels unclear: stop and revert.

