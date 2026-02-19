+++
title = "A Raspberry Pi Camera Timelapse Pipeline"
date = 2025-08-17T09:00:00-05:00
slug = "a-raspberry-pi-camera-timelapse-pipeline"
tags = ["raspberry pi", "camera", "automation", "media"]
categories = ["Raspberry Pi"]
metadescription = "Automating Raspberry Pi camera captures, retention, and video rendering for timelapse projects."
metakeywords = "raspberry pi timelapse, libcamera, ffmpeg"
+++

Timelapse projects become messy when image capture, storage cleanup, and rendering are manual. On Raspberry Pi, I run the whole flow as scheduled services.

A capture timer triggers `libcamera-still` with fixed exposure settings to keep frame-to-frame consistency. Filenames include UTC timestamps so frames sort correctly regardless of locale.

A nightly job compiles fresh clips with `ffmpeg`, then archives originals based on retention policy. I keep full-resolution images for recent days and downscaled copies for long-term history.

Disk quotas and health checks are critical. Without them, the first failure mode is always full storage and silent capture stops.
