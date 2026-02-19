+++
title = "Debian 12 Hardening Retrospective: What I Changed on a Public VPS"
date = 2024-04-10T09:00:00-05:00
slug = "debian-12-hardening-retrospective-what-i-changed-on-a-public-vps"
tags = ["debian", "linux", "hardening", "security", "operations"]
categories = ["Linux", "DevOps"]
metadescription = "A long retrospective on how I hardened a Debian 12 VPS for public internet exposure with practical config details and operational lessons."
metakeywords = "debian 12 hardening guide, linux server security checklist, ssh nftables fail2ban"
+++

I had run Debian servers for years, but in early 2024 I finally treated one of my public VPS nodes like a real production system instead of a hobby box. The goal was simple: reduce attack surface, improve recovery time, and make sure every security control was observable. This post was my full retrospective from that hardening cycle.

![Pexels stock photo: coding workstation](/images/posts/infrastructure/debian-hardening-pexels.jpg)

*Stock photo source: [Pexels](https://www.pexels.com/), image reference: [photo 33349204](https://images.pexels.com/photos/33349204/pexels-photo-33349204.jpeg).* 

## Starting point

At the start, the server had:

- Debian 12 with default package set,
- OpenSSH on port 22 with password auth still enabled,
- UFW rules that had grown ad-hoc over months,
- no structured log forwarding,
- no tested bare-metal restore flow.

It was not "broken," but it was fragile. I needed repeatable hardening, not random tweaks.

## Threat model I used

I focused on common real-world risks for a small internet-facing node:

- credential stuffing and SSH brute force,
- accidental privilege escalation through sloppy sudo rules,
- outdated packages and unattended CVEs,
- noisy scans turning into resource exhaustion,
- weak backup discipline.

I did not design for nation-state adversaries. I designed for realistic internet noise and operator mistakes.

## Base OS cleanup

The first pass was removing packages and services that had no business running there.

```bash
sudo apt purge -y telnet ftp rsync avahi-daemon rpcbind
sudo apt autoremove -y
sudo systemctl disable --now cups bluetooth
sudo ss -tulpn
```

`ss -tulpn` became my quick sanity check after every cleanup step. If I could not justify a listening socket, I removed it.

## SSH hardening pass

I moved SSH to key-only auth, disabled root login, and tightened connection policies.

```conf
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
MaxAuthTries 3
LoginGraceTime 20
AllowUsers gaborops
ClientAliveInterval 300
ClientAliveCountMax 2
```

I also rotated keys, revoked stale keys, and documented who had access. That simple inventory step found two old laptop keys that should have been removed months earlier.

## Network policy with nftables

I replaced my mixed firewall history with one explicit `nftables` ruleset.

```nft
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0;
    policy drop;

    iif lo accept
    ct state established,related accept

    tcp dport {22, 80, 443} ct state new accept

    ip protocol icmp limit rate 20/second accept
    ip6 nexthdr icmpv6 limit rate 20/second accept

    counter drop
  }

  chain forward {
    type filter hook forward priority 0;
    policy drop;
  }

  chain output {
    type filter hook output priority 0;
    policy accept;
  }
}
```

The biggest improvement was not technical complexity. It was predictability.

## Privilege boundaries

I moved away from broad sudo patterns and switched to explicit command allowlists for operational scripts.

```conf
# /etc/sudoers.d/ops
Defaults:gaborops !authenticate
Defaults:gaborops secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
gaborops ALL=(root) NOPASSWD:/usr/bin/systemctl restart nginx,/usr/bin/systemctl status nginx
```

I kept the list intentionally small. Every new command required a ticket note in my ops log.

## Patch and reboot policy

I enabled unattended security updates but I did not blindly trust automation. I added monitoring around it.

```conf
# /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
```

I chose manual reboot windows because this VPS hosted a few stateful services. The policy was:

- apply security updates automatically,
- reboot during weekly maintenance,
- verify app health after reboot with scripted checks.

## Intrusion friction and log quality

I installed `fail2ban`, but I treated it as friction, not full defense.

```ini
# /etc/fail2ban/jail.local
[sshd]
enabled = true
maxretry = 4
findtime = 10m
bantime = 1h
bantime.increment = true
bantime.factor = 2
```

I also pushed journald and auth logs to my central log node. That mattered more than expected because it made pattern analysis possible over time.

## File integrity and backup discipline

I added an integrity baseline and a real restore drill.

- `aide` baseline for critical paths,
- nightly encrypted backups with retention policy,
- monthly restore rehearsal into a throwaway VM.

The first restore rehearsal failed because one secret file had been excluded by mistake. That failure paid for the process immediately.

## Operational runbook changes

Hardening alone was not enough. I also documented response playbooks:

- suspicious SSH activity,
- repeated service crash loop,
- package rollback after broken update,
- disk pressure incident.

Each runbook had command snippets and expected outcomes. During incidents, that removed guesswork.

## Measured outcomes after six weeks

The changes were not dramatic in a marketing sense, but they were meaningful operationally:

- SSH noise dropped from frequent warnings to mostly automated bans,
- no successful password auth attempts after lock-down,
- mean time to recover from deliberate failure tests dropped from 47 minutes to 18 minutes,
- reboot checks became repeatable and boring.

"Boring" was exactly the target state.

## What I would do differently now

If I restarted the same project today, I would:

- codify more hardening in Ansible from day one,
- enforce shell history shipping for privileged sessions,
- add lightweight eBPF telemetry for unusual process behavior,
- standardize service health probes before any maintenance reboot.

## Final checklist I kept

This was the short list I reused on every Debian host afterward:

1. Remove unused packages and services.
2. Lock SSH to key-only + no root.
3. Apply explicit `nftables` default-drop rules.
4. Minimize sudo privileges.
5. Automate security updates with monitored outcomes.
6. Add log centralization and ban automation.
7. Test restore path every month.

That was the cycle that turned one VPS from "probably okay" into an actually defensible small production node.
