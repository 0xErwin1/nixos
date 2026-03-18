# EasyEffects Presets

This directory contains EasyEffects audio presets that are automatically imported into your home-manager configuration.

## Current Presets

- **CMF-Buds-Pro-2** - CMF Buds Pro 2 earbuds
- **FiiO-FD1** - FiiO FD1 IEMs
- **FiiO-FD11** - FiiO FD11 IEMs
- **HyperX-Cloud-Flight-S** - HyperX Cloud Flight S gaming headset
- **Perfect-EQ** - Generic balanced EQ
- **Samsung-Galaxy-Buds2** - Samsung Galaxy Buds2 earbuds
- **Sony-WH-1000XM5** - Sony WH-1000XM5 headphones

## How to Add New Presets

1. Export your preset from EasyEffects (or download from [Community Presets](https://github.com/wwmm/easyeffects/wiki/Community-Presets))
2. Save the `.json` file in this directory
3. **Important**: Remove spaces from the filename (use `-` instead)
   - Good: `My-Preset.json`
   - Bad: `My Preset.json`
4. Rebuild your home-manager configuration:
   ```bash
   git add home-manager/global/easyeffects-presets/Your-New-Preset.json
   home-manager switch --flake .
   ```

## How It Works

The `default.nix` in this directory automatically discovers all `.json` files and adds them to `services.easyeffects.extraPresets`. The presets are installed to:
- `~/.local/share/easyeffects/output/` (for output presets)
- `~/.local/share/easyeffects/input/` (for input presets)

## Preset Format

Presets must be valid EasyEffects JSON format with either `"output"` or `"input"` as the top-level key:

```json
{
  "output": {
    "blocklist": [],
    "plugins_order": ["equalizer#0"],
    "equalizer#0": {
      // ... equalizer settings
    }
  }
}
```

## Community Presets

Find more presets at: https://github.com/wwmm/easyeffects/wiki/Community-Presets
