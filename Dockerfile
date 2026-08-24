ARG KASM_BASE_TAG=1.16.1-rolling-weekly
FROM kasmweb/core-ubuntu-focal:${KASM_BASE_TAG}

# Re-declare after FROM (ARGs before FROM don't survive into the build stage)
ARG ANKI_VERSION=26.08.1

USER root

# --- Anki install-time dependency ---
# install.sh (bundled inside Anki's own tarball) installs Anki's runtime/Qt
# dependencies itself via apt-get, and also calls `xdg-mime` partway through
# (from the xdg-utils package). Everything below runs in one layer so the
# apt package index stays valid for install.sh's own internal `apt-get
# install` call - it's only cleaned up at the very end.
RUN apt-get update && apt-get install -y --no-install-recommends \
      wget \
      zstd \
      ca-certificates \
      xdg-utils \
 && wget -q "https://github.com/ankitects/anki/releases/download/${ANKI_VERSION}/anki-${ANKI_VERSION}-linux-x86_64.tar.zst" \
      -O /tmp/anki.tar.zst \
 && tar --use-compress-program=unzstd -xf /tmp/anki.tar.zst -C /tmp \
 && cd /tmp/anki-linux \
 && ./install.sh \
 && cd / \
 && rm -rf /tmp/anki* /var/lib/apt/lists/*

# --- Desktop launcher icon ---
COPY anki.desktop /home/kasm-user/Desktop/anki.desktop
RUN chmod +x /home/kasm-user/Desktop/anki.desktop \
 && chown kasm-user:kasm-user /home/kasm-user/Desktop/anki.desktop

USER kasm-user

# Record what's inside this image for easy debugging (docker inspect --format).
LABEL anki.version="${ANKI_VERSION}" \
      kasm.base_tag="${KASM_BASE_TAG}"