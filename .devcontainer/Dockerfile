FROM mcr.microsoft.com/devcontainers/universal:2-linux

# Install mosquitto client
RUN apt-get update && apt-get install mosquitto-clients -y

# Install Step CLI
RUN wget https://dl.smallstep.com/gh-release/cli/docs-cli-install/v0.28.7/step-cli_0.28.7-1_amd64.deb && \
    sudo dpkg -i step-cli_0.28.7-1_amd64.deb && \
    rm ./step-cli_0.28.7-1_amd64.deb

# Install mqttui
RUN wget https://github.com/EdJoPaTo/mqttui/releases/download/v0.22.1/mqttui-v0.22.1-x86_64-unknown-linux-gnu.deb && \
    sudo apt-get install ./mqttui-v0.22.1-x86_64-unknown-linux-gnu.deb && \
    rm -rf ./mqttui-v0.22.1-x86_64-unknown-linux-gnu.deb

# Install Flux CLI
RUN curl -s https://fluxcd.io/install.sh | FLUX_VERSION=2.7.0 bash