ARG KASM_BASE_TAG=1.17.0
FROM kasmweb/core-ubuntu-focal:${KASM_BASE_TAG}

# Re-declare after FROM (ARGs before FROM don't survive into the build stage)
ARG ANKI_VERSION=26.08.1

USER root

# --- Anki runtime dependencies ---
# zstd is needed to unpack Anki's .tar.zst release archive.
# The rest are what Anki's own install docs list as required on Debian/Ubuntu
# as of the 26.x "Briefcase" packaging (docs.ankiweb.net/platform/linux/installing.html).
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    zstd \
    ca-certificates \
    libxcb-xinerama0 \
    libxcb-cursor0 \
    libnss3 \
    libxcb-icccm4 \
    libxcb-keysyms1 \
 && rm -rf /var/lib/apt/lists/*

# --- Install Anki ---
# Since 26.05, Anki's Linux tarball is named anki-<version>-linux-x86_64.tar.zst
# and always extracts to a folder called "anki-linux" (not a versioned folder name).
RUN wget -q "https://github.com/ankitects/anki/releases/download/${ANKI_VERSION}/anki-${ANKI_VERSION}-linux-x86_64.tar.zst" \
      -O /tmp/anki.tar.zst \
 && tar --use-compress-program=unzstd -xf /tmp/anki.tar.zst -C /tmp \
 && cd /tmp/anki-linux \
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