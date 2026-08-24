ARG KASM_BASE_TAG=1.17.0
FROM kasmweb/core-ubuntu-focal:${KASM_BASE_TAG}

# Re-declare after FROM (ARGs before FROM don't survive into the build stage)
ARG ANKI_VERSION=26.08.1

USER root

# --- Anki runtime + Qt6 dependencies ---
# zstd is needed to unpack Anki's .tar.zst release archive.
# The rest are the shared libraries Anki's bundled Qt6 GUI needs to run headless-in-container.
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    zstd \
    ca-certificates \
    libnss3 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxrandr2 \
    libxtst6 \
    libasound2 \
    libgbm1 \
    libxkbcommon0 \
    fonts-noto-color-emoji \
 && rm -rf /var/lib/apt/lists/*

# --- Install Anki ---
RUN wget -q "https://github.com/ankitects/anki/releases/download/${ANKI_VERSION}/anki-${ANKI_VERSION}-linux-qt6.tar.zst" \
      -O /tmp/anki.tar.zst \
 && tar --use-compress-program=unzstd -xf /tmp/anki.tar.zst -C /tmp \
 && cd /tmp/anki-${ANKI_VERSION}-linux-qt6 \
 && ./install.sh \
 && cd / \
 && rm -rf /tmp/anki*

# --- Desktop launcher icon ---
COPY anki.desktop /home/kasm-user/Desktop/anki.desktop
RUN chmod +x /home/kasm-user/Desktop/anki.desktop \
 && chown kasm-user:kasm-user /home/kasm-user/Desktop/anki.desktop

USER kasm-user

# Record what's inside this image for easy debugging (docker inspect --format).
LABEL anki.version="${ANKI_VERSION}" \
      kasm.base_tag="${KASM_BASE_TAG}"
