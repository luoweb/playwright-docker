FROM ubuntu:focal as node

ENV NVM_DIR "/root/.nvm"
ENV NVM_VERSION "0.39.1"
ENV NODE_VERSION "18.7.0"
ENV NODE_PATH "$NVM_DIR/v$NODE_VERSION/lib/node_modules"
ENV PATH "$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"

RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN apt update && apt -y install curl libatomic1 ffmpeg make python3 gcc g++ && apt-get clean
RUN curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh" | bash && rm -rf "$NVM_DIR/.cache"

FROM node as base

RUN npm i -g playwright-core && rm -rf /root/.npm
CMD echo "$(lsb_release -d -s), Node $(node -v), Playwright $(playwright -V)"

FROM base as pnpm

ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN npm i -g pnpm && rm -rf /root/.npm

FROM pnpm as chrome
RUN [ $(arch) == "armv7l" ] || [ $(arch) == "aarch64" ] || playwright install --with-deps chrome
CMD echo "$(lsb_release -d -s), Node $(node -v), Playwright $(playwright -V), $(/usr/bin/google-chrome --version)"

FROM pnpm as chromium
RUN playwright install --with-deps chromium
CMD echo "$(lsb_release -d -s), Node $(node -v), Playwright $(playwright -V), $($(echo /root/.cache/ms-playwright/chromium-*/chrome-linux/chrome) --version)"

FROM pnpm as firefox
RUN playwright install --with-deps firefox
CMD echo "$(lsb_release -d -s), Node $(node -v), Playwright $(playwright -V), $($(echo /root/.cache/ms-playwright/firefox-*/firefox/firefox) --version)"

FROM pnpm as webkit
RUN [ $(arch) == "armv7l" ] || playwright install --with-deps webkit
CMD echo "$(lsb_release -d -s), Node $(node -v), Playwright $(playwright -V), $($(echo /root/.cache/ms-playwright/webkit-*/minibrowser-wpe/MiniBrowser) --version)"

FROM pnpm as msedge
RUN apt update && apt -y install gnupg && apt-get clean
RUN [ $(arch) == "armv7l" ] || [ $(arch) == "aarch64" ] || playwright install --with-deps msedge
CMD echo "$(lsb_release -d -s), Node $(node -v), Playwright $(playwright -V), $(/usr/bin/microsoft-edge --version)"

FROM chrome as all
RUN apt update && apt -y install gnupg && apt-get clean
RUN playwright install --with-deps chromium
RUN playwright install --with-deps firefox
RUN [ $(arch) == "armv7l" ] || playwright install --with-deps webkit
RUN [ $(arch) == "armv7l" ] || [ $(arch) == "aarch64" ] || playwright install --with-deps msedge
CMD echo "$(lsb_release -d -s), Node $(node -v), Playwright $(playwright -V), $(/usr/bin/google-chrome --version), $($(echo /root/.cache/ms-playwright/chromium-*/chrome-linux/chrome) --version), $($(echo /root/.cache/ms-playwright/firefox-*/firefox/firefox) --version), $($(echo /root/.cache/ms-playwright/webkit-*/minibrowser-wpe/MiniBrowser) --version), $(/usr/bin/microsoft-edge --version)"
