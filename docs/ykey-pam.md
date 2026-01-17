# YubiKey for PAM login / sudo (manual)

generated with chatgpt - so verify before following.

## Goal
Require YubiKey presence for login or sudo, without locking yourself out.

## Preconditions
- System already usable without YubiKey
- Root access
- Physical access

## How to do it

1. Install required packages:
`pacman -S yubikey-manager yubikey-touch-detector pam-u2f`
2. Generate U2F mapping for your user:
```
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys
```

3. Add PAM rule (example: sudo):
Edit: `/etc/pam.d/sudo`
Add **above** existing auth lines:
```
auth required pam_u2f.so cue
```

4. Open a second root shell **before testing**.

5. Test sudo in the first shell.

## Safety rules
- Always keep one root shell open while editing PAM.
- Do not enforce YubiKey-only auth.
- If locked out: boot live ISO, revert PAM file.
