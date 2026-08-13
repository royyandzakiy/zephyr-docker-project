# Setting up CI

## Self-hosted Runner setup

Activate runners by opening the settings for self-hosted runner

```bash
https://github.com/YOUR_USERNAME/zephyr-docker-project/settings/actions/runners/new?arch=x64&os=linux
```

Download the actions runner for linux to `/`

```bash
# Create a folder
cd /
mkdir actions-runner && cd actions-runner

# Download the latest runner package
curl -o actions-runner-linux-x64-2.336.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.336.0/actions-runner-linux-x64-2.336.0.tar.gz

# Optional: Validate the hash
echo "04cf0be1aff4c3ec3554466c39124ca250e3effd8873bb7e8d68535aa9505d5d  actions-runner-linux-x64-2.336.0.tar.gz" | shasum -a 256 -c

# Extract the installer
tar xzf ./actions-runner-linux-x64-2.336.0.tar.gz
```

Run the actions-runner NOT as root (here we create a user called runner)

```bash
# Create a non-root user (e.g., runner)
useradd -m runner
chown -R runner:runner /actions-runner

# Switch to the new user and run the script
su runner -c bash
cd /actions-runner

# config if not yet
# ./config.sh --url https://github.com/YOUR_USERNAME/zephyr-docker-project --token YOUR_TOKEN_HERE"

./run.sh
```

### Troubleshooting

Error: Cannot configure the runner because it is already configured. To reconfigure the runner, run 'config.cmd remove' or './config.sh remove' first.

```bash
su runner -c bash
./config.sh remove --token YOUR_TOKEN_HERE
```

Error: A runner already exists

```bash
# √ Connected to GitHub
# A session for this runner already exists.
# 2026-08-13 11:57:51Z: Runner connect error: Error: Conflict. Retrying until reconnected.

# Find the running runner processes
ps aux | grep -i Runner.Listener

pkill -9 -f Runner.Listener || true
./run.sh
```

## Build & Flashing

```bash
west build -b nrf5340dk/nrf5340/cpuapp -d build_nrf -p always

west flash -r nrfjprog --snr 1050073602 -d build_nrf
# or
nrfjprog --snr 1050073602 --program /workspaces/zephyr-docker-project/build_nrf/zephyr/zephyr.hex --ch
iperase --reset
```