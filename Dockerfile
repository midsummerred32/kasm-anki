ARG KASM_BASE_TAG=1.16.1-rolling-weekly
FROM kasmweb/core-ubuntu-noble:${KASM_BASE_TAG}

# Re-declare after FROM (ARGs before FROM don't survive into the build stage)
ARG ANKI_VERSION=26.08.1

USER root

# Kasm's own convention (see kasm.com/docs/latest/how_to/building_images.html):
# customizations are written into a seed profile directory, kasm-default-profile,
# which Kasm copies into the real session home (kasm-user) at container start.
# Writing straight to /home/kasm-user during the build gets ignored/overwritten,
# which is why the desktop icon didn't show up before.
ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR $HOME

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
# install.sh drops a .desktop file into /usr/share/applications itself
# (this is what gives Anki its app-menu entry); we copy that same file onto
# the seed profile's Desktop so it also shows as a desktop icon.
RUN cp /usr/local/share/applications/anki.desktop $HOME/Desktop/anki.desktop \
 && chmod +x $HOME/Desktop/anki.desktop \
 && chown 1000:0 $HOME/Desktop/anki.desktop

# --- Auto-launch Anki when the session starts ---
# custom_startup.sh is Kasm's hook for this; desktop_ready blocks until the
# XFCE desktop has finished loading so Anki doesn't try to open too early.
RUN echo '/usr/bin/desktop_ready && anki &' > $STARTUPDIR/custom_startup.sh \
 && chmod +x $STARTUPDIR/custom_startup.sh

# Match ownership convention used by the core image (uid 1000, gid 0)
RUN chown -R 1000:0 $HOME

USER 1000

# Record what's inside this image for easy debugging (docker inspect --format).
LABEL anki.version="${ANKI_VERSION}" \
      kasm.base_tag="${KASM_BASE_TAG}"