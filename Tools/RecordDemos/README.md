# Record Demos

Manual tooling for regenerating the README GIFs from a booted iOS Simulator.

```sh
Tools/RecordDemos/record_demos.sh
```

The script builds a temporary simulator app against the local package source, records the standard-title and large-title demos, and overwrites:

- `Docs/demo-default.gif`
- `Docs/demo-large-title.gif`

Use `DEVICE_ID=<simulator-udid>` to target a specific booted simulator.

```sh
DEVICE_ID=00000000-0000-0000-0000-000000000000 Tools/RecordDemos/record_demos.sh
```

Use `--build-only` to verify the temporary app and converter compile without recording.
