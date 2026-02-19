+++
title = "Secure Remote Access to Raspberry Pi with WireGuard"
date = 2024-12-15T09:00:00-05:00
slug = "secure-remote-access-to-raspberry-pi-with-wireguard"
tags = ["raspberry pi", "wireguard", "security", "linux"]
categories = ["Raspberry Pi"]
metadescription = "How I expose Raspberry Pi services safely using WireGuard instead of public ports."
metakeywords = "raspberry pi wireguard, remote access, vpn"
+++

Exposing SSH or dashboards directly to the internet is unnecessary risk for small deployments. WireGuard gives a cleaner and safer remote access model.

I keep the Pi behind NAT, open only the VPN endpoint on a gateway, and route internal management traffic through private tunnel addresses.

Keys are rotated on a schedule, and each device gets its own peer profile. That makes revocation simple when a node is retired.

Combined with firewall rules that allow admin ports only on the VPN interface, this approach has been low-maintenance and resilient.
