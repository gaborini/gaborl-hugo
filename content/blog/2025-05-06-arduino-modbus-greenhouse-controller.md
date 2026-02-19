+++
title = "Building a Modbus Greenhouse Controller with Arduino"
date = 2025-05-06T09:00:00-05:00
slug = "building-a-modbus-greenhouse-controller-with-arduino"
tags = ["arduino", "modbus", "rs485", "automation"]
categories = ["Arduino"]
metadescription = "Using Arduino and RS485 Modbus to run a resilient greenhouse control loop."
metakeywords = "arduino modbus, rs485 greenhouse, industrial protocol"
+++

For greenhouse automation, I wanted a protocol that survives long cable runs and noisy environments. Modbus RTU over RS485 is still one of the best options for this type of deployment.

I split the system into three layers: sensing, control logic, and actuation. Sensor values are exposed as holding registers, while relay and valve commands are written through a small command map. Keeping register addresses documented in a table prevented integration mistakes later.

The control loop is intentionally conservative. I use hysteresis bands instead of single thresholds to avoid relay chatter, and I enforce minimum on/off intervals for pumps and fans.

A dedicated heartbeat register tells me if each device is alive. If heartbeat updates stop, the controller falls back to a safe default profile instead of trying to continue with stale readings.
