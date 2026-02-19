+++
title = "Arduino Sensor Calibration and Filtering Playbook"
date = 2026-02-12T09:00:00-05:00
slug = "arduino-sensor-calibration-and-filtering-playbook"
tags = ["arduino", "calibration", "signal-processing", "sensors", "data-quality"]
categories = ["Arduino"]
metadescription = "A practical and detailed workflow for calibrating and filtering Arduino sensor data for production use."
metakeywords = "arduino sensor calibration, filtering sensor noise, embedded signal processing"
+++

Many embedded dashboards look stable only because noise is hidden by aggressive averaging. That is not the same as accurate measurement. This post describes a full calibration and filtering workflow you can repeat for temperature, pressure, flow, and similar sensors.

## 1. Calibration starts with reference quality

A sensor can only be calibrated against something better than itself. Use a trustworthy reference instrument with known uncertainty. Record that uncertainty in your notes.

Collect calibration points across the real operating range, not only near room conditions. For example, if expected temperature is `-5C` to `45C`, measure at least 5 points across that interval.

## 2. Build a calibration dataset correctly

For each point:

- Wait for stabilization time
- Capture multiple samples (for example 50)
- Store mean and standard deviation
- Record ambient conditions that may affect readings

A single sample per point is insufficient because you lose information about repeatability.

## 3. Fit model based on sensor behavior

Common choices:

- Simple offset correction
- Linear scale and offset
- Piecewise linear mapping
- Polynomial fit (use cautiously)

Keep model complexity as low as possible. Overfitted curves can look perfect in the lab and fail badly in the field.

## 4. Runtime filtering strategy

Use different filters for different noise profiles:

- Moving average: good for high-frequency jitter
- Exponential smoothing: low memory, good default
- Median filter: effective against outliers/spikes

I usually combine median (small window) + exponential smoothing.

```cpp
float ema(float prev, float sample, float alpha) {
  return (alpha * sample) + ((1.0f - alpha) * prev);
}
```

Choose `alpha` from response requirements. Faster dynamics need larger alpha.

## 5. Latency budget and control impact

Filtering adds delay. In monitoring-only systems, this is often fine. In control loops, delay can destabilize behavior.

Define a maximum tolerated signal delay before choosing filter windows. If your actuator loop runs at 10 Hz, a 2-second smoothing window may be unacceptable.

## 6. Drift monitoring in production

Calibration is not one-time work. Sensor drift happens due to aging, contamination, and mechanical stress.

Add drift indicators:

- Difference between redundant sensors
- Change in baseline offset over time
- Unusual variance increase

When drift exceeds threshold, trigger maintenance flag or recalibration schedule.

## 7. Data quality metadata

Every published reading should include quality context:

- raw value
- calibrated value
- filter status
- confidence/validity flag
- calibration version

Without metadata, downstream systems cannot tell whether suspicious values are real events or processing artifacts.

## 8. Practical validation routine

After implementing calibration and filters:

- Replay captured noisy datasets through firmware logic
- Compare output against reference traces
- Verify startup behavior before filter warm-up completes
- Test extreme values and out-of-range handling

If you do not test startup and edge values, most field bugs appear there first.

## Final note

Good sensor data is engineered. Calibration, filtering, and quality metadata should be treated as core product features, not polish added at the end.
