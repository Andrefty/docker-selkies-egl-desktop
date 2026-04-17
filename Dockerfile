# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Supported base images: Ubuntu 24.04, 22.04, 20.04
ARG DISTRIB_IMAGE=ubuntu
ARG DISTRIB_RELEASE=24.04
FROM ${DISTRIB_IMAGE}:${DISTRIB_RELEASE}
ARG DISTRIB_IMAGE
ARG DISTRIB_RELEASE

LABEL maintainer="https://github.com/ehfd,https://github.com/danisla"

ARG DEBIAN_FRONTEND=noninteractive
# Configure rootless user environment for constrained conditions without escalated root privileges inside containers
ARG TZ=UTC
ENV PASSWD=mypasswd
RUN apt-get clean && apt-get update && apt-get dist-upgrade -y && apt-get install --no-install-recommends -y \
        apt-utils \
        dbus-user-session \
        fakeroot \
        fuse \
        kmod \
        locales \
        ssl-cert \
        sudo \
        udev \
        tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/* && \
    locale-gen en_US.UTF-8 && \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone && \
    # Only use sudo-root for root-owned directory (/dev, /proc, /sys) or user/group permission operations, not for apt-get installation or file/directory operations
    mv -f /usr/bin/sudo /usr/bin/sudo-root && \
    ln -snf /usr/bin/fakeroot /usr/bin/sudo && \
    groupadd -g 1000 ubuntu || echo 'Failed to add ubuntu group' && \
    useradd -ms /bin/bash ubuntu -u 1000 -g 1000 || echo 'Failed to add ubuntu user' && \
    usermod -a -G adm,audio,cdrom,dialout,dip,fax,floppy,games,input,lp,plugdev,render,ssl-cert,sudo,tape,tty,video,voice ubuntu && \
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "ubuntu:${PASSWD}" | chpasswd && \
    chown -R -f -h --no-preserve-root ubuntu:ubuntu / || echo 'Failed to set filesystem ownership in some paths to ubuntu user' && \
    # Preserve setuid/setgid removed by chown
    chmod -f 4755 /usr/lib/dbus-1.0/dbus-daemon-launch-helper /usr/bin/chfn /usr/bin/chsh /usr/bin/mount /usr/bin/gpasswd /usr/bin/passwd /usr/bin/newgrp /usr/bin/umount /usr/bin/su /usr/bin/sudo-root /usr/bin/fusermount || echo 'Failed to set chmod setuid for some paths' && \
    chmod -f 2755 /var/local /var/mail /usr/sbin/unix_chkpwd /usr/sbin/pam_extrausers_chkpwd /usr/bin/expiry /usr/bin/chage || echo 'Failed to set chmod setgid for some paths'

# Set locales
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

USER 1000
# Use BUILDAH_FORMAT=docker in buildah
SHELL ["/usr/bin/fakeroot", "--", "/bin/sh", "-c"]

# Install operating system libraries or packages
RUN apt-get update && apt-get install --no-install-recommends -y \
        # Operating system packages
        software-properties-common \
        build-essential \
        ca-certificates \
        cups-browsed \
        cups-bsd \
        cups-common \
        cups-filters \
        printer-driver-cups-pdf \
        alsa-base \
        alsa-utils \
        file \
        gnupg \
        curl \
        wget \
        bzip2 \
        gzip \
        xz-utils \
        unar \
        rar \
        unrar \
        zip \
        unzip \
        zstd \
        gcc \
        git \
        dnsutils \
        coturn \
        jq \
        python3 \
        python3-cups \
        python3-numpy \
        nano \
        vim \
        htop \
        fonts-dejavu \
        fonts-freefont-ttf \
        fonts-hack \
        fonts-liberation \
        fonts-noto \
        fonts-noto-cjk \
        fonts-noto-cjk-extra \
        fonts-noto-color-emoji \
        fonts-noto-extra \
        fonts-noto-ui-extra \
        fonts-noto-hinted \
        fonts-noto-mono \
        fonts-noto-unhinted \
        fonts-opensymbol \
        fonts-symbola \
        fonts-ubuntu \
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        lame \
        less \
        libavcodec-extra \
        libpulse0 \
        supervisor \
        net-tools \
        packagekit-tools \
        pkg-config \
        mesa-utils \
        mesa-va-drivers \
        libva2 \
        vainfo \
        vdpau-driver-all \
        libvdpau-va-gl1 \
        vdpauinfo \
        mesa-vulkan-drivers \
        vulkan-tools \
        radeontop \
        libvulkan-dev \
        ocl-icd-libopencl1 \
        clinfo \
        xkb-data \
        xauth \
        xbitmaps \
        xdg-user-dirs \
        xdg-utils \
        xfonts-base \
        xfonts-scalable \
        xinit \
        xsettingsd \
        libxrandr-dev \
        x11-xkb-utils \
        x11-xserver-utils \
        x11-utils \
        x11-apps \
        xserver-xorg-input-all \
        xserver-xorg-input-wacom \
        xserver-xorg-video-all \
        xserver-xorg-video-intel \
        xserver-xorg-video-qxl \
        # NVIDIA driver installer dependencies
        libc6-dev \
        libpci3 \
        libelf-dev \
        libglvnd-dev \
        # OpenGL libraries
        libxau6 \
        libxdmcp6 \
        libxcb1 \
        libxext6 \
        libx11-6 \
        libxv1 \
        libxtst6 \
        libdrm2 \
        libegl1 \
        libgl1 \
        libopengl0 \
        libgles1 \
        libgles2 \
        libglvnd0 \
        libglx0 \
        libglu1 \
        libsm6 \
        # NGINX web server
        nginx \
        apache2-utils \
        netcat-openbsd && \
    # Sanitize NGINX path
    sed -i -e 's/\/var\/log\/nginx\/access\.log/\/dev\/stdout/g' -e 's/\/var\/log\/nginx\/error\.log/\/dev\/stderr/g' -e 's/\/run\/nginx\.pid/\/tmp\/nginx\.pid/g' /etc/nginx/nginx.conf && \
    echo "error_log /dev/stderr;" >> /etc/nginx/nginx.conf && \
    # PipeWire and WirePlumber
    mkdir -pm755 /etc/apt/trusted.gpg.d && curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xFC43B7352BCC0EC8AF2EEB8B25088A0359807596" | gpg --dearmor -o /etc/apt/trusted.gpg.d/pipewire-debian-ubuntu-pipewire-upstream.gpg && \
    mkdir -pm755 /etc/apt/sources.list.d && echo "deb https://ppa.launchpadcontent.net/pipewire-debian/pipewire-upstream/ubuntu $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"') main" > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-pipewire-upstream-$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"').list" && \
    mkdir -pm755 /etc/apt/sources.list.d && echo "deb https://ppa.launchpadcontent.net/pipewire-debian/wireplumber-upstream/ubuntu $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"') main" > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-wireplumber-upstream-$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"').list" && \
    apt-get update && apt-get install --no-install-recommends -y \
        pipewire \
        pipewire-alsa \
        pipewire-audio-client-libraries \
        pipewire-jack \
        pipewire-locales \
        pipewire-v4l2 \
        pipewire-vulkan \
        pipewire-libcamera \
        gstreamer1.0-libcamera \
        gstreamer1.0-pipewire \
        libpipewire-0.3-modules \
        libpipewire-module-x11-bell \
        libspa-0.2-bluetooth \
        libspa-0.2-jack \
        libspa-0.2-modules \
        wireplumber \
        wireplumber-locales \
        gir1.2-wp-0.5 && \
    # Packages only meant for x86_64
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    dpkg --add-architecture i386 && apt-get update && apt-get install --no-install-recommends -y \
        intel-gpu-tools \
        nvtop \
        va-driver-all \
        i965-va-driver-shaders \
        intel-media-va-driver-non-free \
        va-driver-all:i386 \
        i965-va-driver-shaders:i386 \
        intel-media-va-driver-non-free:i386 \
        libva2:i386 \
        vdpau-driver-all:i386 \
        mesa-vulkan-drivers:i386 \
        libvulkan-dev:i386 \
        libc6:i386 \
        libxau6:i386 \
        libxdmcp6:i386 \
        libxcb1:i386 \
        libxext6:i386 \
        libx11-6:i386 \
        libxv1:i386 \
        libxtst6:i386 \
        libdrm2:i386 \
        libegl1:i386 \
        libgl1:i386 \
        libopengl0:i386 \
        libgles1:i386 \
        libgles2:i386 \
        libglvnd0:i386 \
        libglx0:i386 \
        libglu1:i386 \
        libsm6:i386; fi && \
    # Install nvidia-vaapi-driver, requires the kernel parameter `nvidia_drm.modeset=1` set to run correctly
    if [ "$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"')" \> "20.04" ]; then \
    apt-get update && apt-get install --no-install-recommends -y \
        meson \
        gstreamer1.0-plugins-bad \
        libffmpeg-nvenc-dev \
        libva-dev \
        libegl-dev \
        libgstreamer-plugins-bad1.0-dev && \
    NVIDIA_VAAPI_DRIVER_VERSION="$(curl -fsSL "https://api.github.com/repos/elFarto/nvidia-vaapi-driver/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && curl -fsSL "https://github.com/elFarto/nvidia-vaapi-driver/archive/v${NVIDIA_VAAPI_DRIVER_VERSION}.tar.gz" | tar -xzf - && mv -f nvidia-vaapi-driver* nvidia-vaapi-driver && cd nvidia-vaapi-driver && meson setup build && meson install -C build && rm -rf /tmp/*; fi && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/* && \
    echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf && \
    # Configure OpenCL manually
    mkdir -pm755 /etc/OpenCL/vendors && echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd && \
    # Configure Vulkan manually
    VULKAN_API_VERSION=$(dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)') && \
    mkdir -pm755 /etc/vulkan/icd.d/ && echo "{\n\
    \"file_format_version\" : \"1.0.0\",\n\
    \"ICD\": {\n\
        \"library_path\": \"libGLX_nvidia.so.0\",\n\
        \"api_version\" : \"${VULKAN_API_VERSION}\"\n\
    }\n\
}" > /etc/vulkan/icd.d/nvidia_icd.json && \
    # Configure EGL manually
    mkdir -pm755 /usr/share/glvnd/egl_vendor.d/ && echo "{\n\
    \"file_format_version\" : \"1.0.0\",\n\
    \"ICD\": {\n\
        \"library_path\": \"libEGL_nvidia.so.0\"\n\
    }\n\
}" > /usr/share/glvnd/egl_vendor.d/10_nvidia.json
# Expose NVIDIA libraries and paths
ENV PATH="/usr/local/nvidia/bin${PATH:+:${PATH}}"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}/usr/local/nvidia/lib:/usr/local/nvidia/lib64"
# Make all NVIDIA GPUs visible by default
ENV NVIDIA_VISIBLE_DEVICES=all
# All NVIDIA driver capabilities should preferably be used, check `NVIDIA_DRIVER_CAPABILITIES` inside the container if things do not work
ENV NVIDIA_DRIVER_CAPABILITIES=all
# Disable VSYNC for NVIDIA GPUs
ENV __GL_SYNC_TO_VBLANK=0
# Set default DISPLAY environment
ENV DISPLAY=":20"

# Anything above this line should always be kept the same between docker-selkies-glx-desktop and docker-selkies-egl-desktop

# Default environment variables (default password is "mypasswd")
ENV DISPLAY_SIZEW=1920
ENV DISPLAY_SIZEH=1080
ENV DISPLAY_REFRESH=60
ENV DISPLAY_DPI=96
ENV DISPLAY_CDEPTH=24
ENV VGL_DISPLAY=egl
ENV KASMVNC_ENABLE=false
ENV SELKIES_ENCODER=nvh264enc
ENV SELKIES_ENABLE_RESIZE=false
ENV SELKIES_ENABLE_BASIC_AUTH=true

# Install Xvfb
RUN apt-get update && apt-get install --no-install-recommends -y \
        xvfb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*

# Install VirtualGL and make libraries available for preload
RUN cd /tmp && VIRTUALGL_VERSION="$(curl -fsSL "https://api.github.com/repos/VirtualGL/virtualgl/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    dpkg --add-architecture i386 && \
    curl -fsSL -O "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" && \
    curl -fsSL -O "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    apt-get update && apt-get install -y --no-install-recommends "./virtualgl_${VIRTUALGL_VERSION}_amd64.deb" "./virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    rm -f "virtualgl_${VIRTUALGL_VERSION}_amd64.deb" "virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    chmod -f u+s /usr/lib/libvglfaker.so /usr/lib/libvglfaker-nodl.so /usr/lib/libvglfaker-opencl.so /usr/lib/libdlfaker.so /usr/lib/libgefaker.so && \
    chmod -f u+s /usr/lib32/libvglfaker.so /usr/lib32/libvglfaker-nodl.so /usr/lib32/libvglfaker-opencl.so /usr/lib32/libdlfaker.so /usr/lib32/libgefaker.so && \
    chmod -f u+s /usr/lib/i386-linux-gnu/libvglfaker.so /usr/lib/i386-linux-gnu/libvglfaker-nodl.so /usr/lib/i386-linux-gnu/libvglfaker-opencl.so /usr/lib/i386-linux-gnu/libdlfaker.so /usr/lib/i386-linux-gnu/libgefaker.so; \
    elif [ "$(dpkg --print-architecture)" = "arm64" ]; then \
    curl -fsSL -O "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_arm64.deb" && \
    apt-get update && apt-get install -y --no-install-recommends ./virtualgl_${VIRTUALGL_VERSION}_arm64.deb && \
    rm -f "virtualgl_${VIRTUALGL_VERSION}_arm64.deb" && \
    chmod -f u+s /usr/lib/libvglfaker.so /usr/lib/libvglfaker-nodl.so /usr/lib/libdlfaker.so /usr/lib/libgefaker.so; fi && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*

# Anything below this line should always be kept the same between docker-selkies-glx-desktop and docker-selkies-egl-desktop

# Install KDE and other GUI packages
ARG INSTALL_LIBREOFFICE=0
ARG INSTALL_STEAM=1
ARG STEAM_PREBOOTSTRAP=1
ARG STEAM_PREBOOTSTRAP_STRICT=0
ENV STEAM_SEED_ROOT=/opt/steam-seed
ENV SELKIES_STEAM_HYDRATE=1
ENV SELKIES_STEAM_NATIVE_DEFAULT=1
ENV SELKIES_STEAM_NAMESPACELESS_PATCH=1
ENV SELKIES_STEAM_RUN_STEAMDEPS=0
RUN mkdir -pm755 /etc/apt/preferences.d && echo "Package: firefox*\n\
Pin: version 1:1snap*\n\
Pin-Priority: -1" > /etc/apt/preferences.d/firefox-nosnap && \
    mkdir -pm755 /etc/apt/trusted.gpg.d && curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x738BEB9321D1AAEC13EA9391AEBDF4819BE21867" | gpg --dearmor -o /etc/apt/trusted.gpg.d/mozillateam-ubuntu-ppa.gpg && \
    mkdir -pm755 /etc/apt/sources.list.d && echo "deb https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"') main" > "/etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"').list" && \
    apt-get update && apt-get install --no-install-recommends -y \
        kde-baseapps \
        plasma-desktop \
        plasma-workspace \
        adwaita-icon-theme-full \
        appmenu-gtk3-module \
        ark \
        aspell \
        aspell-en \
        breeze \
        breeze-cursor-theme \
        breeze-gtk-theme \
        breeze-icon-theme \
        dbus-x11 \
        debconf-kde-helper \
        desktop-file-utils \
        dolphin \
        dolphin-plugins \
        enchant-2 \
        fcitx \
        fcitx-frontend-gtk2 \
        fcitx-frontend-gtk3 \
        fcitx-frontend-qt5 \
        fcitx-module-dbus \
        fcitx-module-kimpanel \
        fcitx-module-lua \
        fcitx-module-x11 \
        fcitx-tools \
        fcitx-hangul \
        fcitx-libpinyin \
        fcitx-m17n \
        fcitx-mozc \
        fcitx-sayura \
        fcitx-unikey \
        filelight \
        frameworkintegration \
        gwenview \
        haveged \
        hunspell \
        im-config \
        kwrite \
        kcalc \
        kcharselect \
        kdeadmin \
        kde-config-fcitx \
        kde-config-gtk-style \
        kde-config-gtk-style-preview \
        kdeconnect \
        kdegraphics-thumbnailers \
        kde-spectacle \
        kdf \
        kdialog \
        kfind \
        kget \
        khotkeys \
        kimageformat-plugins \
        kinfocenter \
        kio \
        kio-extras \
        kmag \
        kmenuedit \
        kmix \
        kmousetool \
        kmouth \
        ksshaskpass \
        ktimer \
        kwin-addons \
        kwin-x11 \
        libdbusmenu-glib4 \
        libdbusmenu-gtk3-4 \
        libgail-common \
        libgdk-pixbuf2.0-bin \
        libgtk2.0-bin \
        libgtk-3-bin \
        libkf5baloowidgets-bin \
        libkf5dbusaddons-bin \
        libkf5iconthemes-bin \
        libkf5kdelibs4support5-bin \
        libkf5khtml-bin \
        libkf5parts-plugins \
        libqt5multimedia5-plugins \
        librsvg2-common \
        media-player-info \
        okular \
        okular-extra-backends \
        plasma-browser-integration \
        plasma-calendar-addons \
        plasma-dataengines-addons \
        plasma-discover \
        plasma-integration \
        plasma-runners-addons \
        plasma-widgets-addons \
        print-manager \
        qapt-deb-installer \
        qml-module-org-kde-runnermodel \
        qml-module-org-kde-qqc2desktopstyle \
        qml-module-qtgraphicaleffects \
        qml-module-qt-labs-platform \
        qml-module-qtquick-xmllistmodel \
        qt5-gtk-platformtheme \
        qt5-image-formats-plugins \
        qt5-style-plugins \
        qtspeech5-flite-plugin \
        qtvirtualkeyboard-plugin \
        software-properties-qt \
        sonnet-plugins \
        sweeper \
        systemsettings \
        ubuntu-drivers-common \
        vlc \
        vlc-plugin-access-extra \
        vlc-plugin-notify \
        vlc-plugin-samba \
        vlc-plugin-skins2 \
        vlc-plugin-video-splitter \
        vlc-plugin-visualization \
        xdg-user-dirs \
        xdg-utils \
        firefox \
        transmission-qt && \
    if [ "$(dpkg --print-architecture)" = "amd64" ] && [ "${INSTALL_STEAM}" = "1" ]; then \
    add-apt-repository -y multiverse && apt-get update && \
    curl -fsSL -o /tmp/steam_latest.deb https://repo.steampowered.com/steam/archive/precise/steam_latest.deb && \
    apt-get install --install-recommends -y /tmp/steam_latest.deb && rm -f /tmp/steam_latest.deb && \
    apt-get install --no-install-recommends -y \
        bubblewrap \
        libasound2-plugins:i386 \
        libdbus-1-3:i386 \
        libfontconfig1:i386 \
        libfreetype6:i386 \
        libgcc-s1:i386 \
        libgtk2.0-0:i386 \
        libnss3:i386 \
        libpipewire-0.3-0:i386 \
        libstdc++6:i386 \
        libxcb-res0:i386 \
        zlib1g:i386 && \
    command -v bwrap >/dev/null 2>&1 && \
    install -d -m 755 /usr/local/share/selkies/steam && \
    printf '%s\n' '#!/bin/sh' \
        'while [ "$#" -gt 0 ]; do' \
        '  case "$1" in' \
        '    --*) shift ;;' \
        '    *) break ;;' \
        '  esac' \
        'done' \
        'exec "$@"' > /usr/local/share/selkies/steam/_v2-entry-point && \
    chmod -f 755 /usr/local/share/selkies/steam/_v2-entry-point && \
    printf '%s\n' '#!/bin/sh' \
        'set -eu' \
        'PATCH_SRC=/usr/local/share/selkies/steam/_v2-entry-point' \
        '[ -x "${PATCH_SRC}" ] || exit 0' \
        'LOOPS="${SELKIES_STEAM_PATCH_LOOPS:-1800}"' \
        'SLEEP_SECONDS="${SELKIES_STEAM_PATCH_INTERVAL:-0.1}"' \
        'while [ "${LOOPS}" -gt 0 ]; do' \
        '  for target in "${HOME}/.steam/debian-installation/ubuntu12_64/steam-runtime-sniper/_v2-entry-point" "${HOME}/.steam/steam/ubuntu12_64/steam-runtime-sniper/_v2-entry-point" "${HOME}/.local/share/Steam/steamrt64/steam-runtime-steamrt/_v2-entry-point" "${HOME}/.local/share/Steam/steamapps/common/SteamLinuxRuntime_soldier/_v2-entry-point" "${HOME}/.local/share/Steam/steamapps/common/SteamLinuxRuntime_sniper/_v2-entry-point"; do' \
        '    [ -f "${target}" ] || continue' \
        '    [ -w "${target}" ] || continue' \
        '    size="$(stat -c %s "${target}" 2>/dev/null || printf "0")"' \
        '    tmp="$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/selkies-steam-entrypoint.XXXXXX" 2>/dev/null || mktemp /tmp/selkies-steam-entrypoint.XXXXXX)"' \
        '    cp -f "${PATCH_SRC}" "${tmp}" 2>/dev/null || { rm -f "${tmp}"; continue; }' \
        '    if [ "${size}" -gt 0 ] 2>/dev/null; then truncate -s "${size}" "${tmp}" 2>/dev/null || true; fi' \
        '    chmod +x "${tmp}" 2>/dev/null || true' \
        '    cat "${tmp}" > "${target}" 2>/dev/null || cp -f "${tmp}" "${target}" 2>/dev/null || true' \
        '    chmod +x "${target}" 2>/dev/null || true' \
        '    rm -f "${tmp}"' \
        '  done' \
        '  sleep "${SLEEP_SECONDS}"' \
        '  LOOPS=$((LOOPS - 1))' \
        'done' > /usr/local/bin/steam-namespaceless-patcher && \
    chmod -f 755 /usr/local/bin/steam-namespaceless-patcher && \
    if [ -x /usr/bin/steamdeps ] && [ ! -e /usr/bin/steamdeps.real ]; then \
        mv -f /usr/bin/steamdeps /usr/bin/steamdeps.real; \
    fi && \
    printf '%s\n' '#!/bin/sh' \
        'if [ "${SELKIES_STEAM_RUN_STEAMDEPS:-0}" = "1" ] && [ -x /usr/bin/steamdeps.real ]; then' \
        '  exec /usr/bin/steamdeps.real "$@"' \
        'fi' \
        'echo "steamdeps: skipping package manager checks in containerized sessions; set SELKIES_STEAM_RUN_STEAMDEPS=1 to re-enable." >&2' \
        'exit 0' > /usr/bin/steamdeps && \
    chmod -f 755 /usr/bin/steamdeps && \
    printf '%s\n' '#!/bin/sh' \
        'set -eu' \
        'find_steam_launcher() {' \
        '  for candidate in /usr/games/steam /usr/bin/steam /usr/lib/steam/steam /usr/lib/steam/steam.sh; do' \
        '    [ -x "${candidate}" ] || continue' \
        '    resolved="$(readlink -f "${candidate}" 2>/dev/null || printf "%s" "${candidate}")"' \
        '    case "${resolved}" in' \
        '      /usr/local/bin/steam|/usr/local/bin/steam-pressure-vessel) continue ;;' \
        '    esac' \
        '    printf "%s" "${candidate}"' \
        '    return 0' \
        '  done' \
        '  return 1' \
        '}' \
        'STEAM_LAUNCHER="$(find_steam_launcher || true)"' \
        'if [ -z "${STEAM_LAUNCHER}" ]; then' \
        '  echo "ERROR: Steam launcher binary was not found. Checked /usr/games/steam, /usr/bin/steam, /usr/lib/steam/steam, /usr/lib/steam/steam.sh." >&2' \
        '  exit 127' \
        'fi' \
        '# Default to runtime-enabled, non-heavy mode for compatibility without forcing pressure-vessel.' \
        'if [ "${SELKIES_STEAM_NATIVE_DEFAULT:-1}" = "1" ]; then' \
        '  : "${STEAM_RUNTIME:=1}"' \
        '  : "${STEAM_RUNTIME_HEAVY:=0}"' \
        '  export STEAM_RUNTIME STEAM_RUNTIME_HEAVY' \
        'fi' \
        'if [ "${SELKIES_STEAM_NAMESPACELESS_PATCH:-1}" = "1" ]; then' \
        '  rm -f /run/systemd/container /run/host/container-manager >/dev/null 2>&1 || true' \
        '  mkdir -p /run/pressure-vessel >/dev/null 2>&1 || true' \
        '  if [ -x /usr/local/bin/steam-namespaceless-patcher ]; then' \
        '    /usr/local/bin/steam-namespaceless-patcher >/dev/null 2>&1 &' \
        '  fi' \
        'fi' \
        'exec "${STEAM_LAUNCHER}" "$@"' > /usr/local/bin/steam && \
    printf '%s\n' '#!/bin/sh' \
        'set -eu' \
        '# Force pressure-vessel path for Proton-focused sessions on hosts with working user namespaces.' \
        'export SELKIES_STEAM_NATIVE_DEFAULT=0' \
        'export STEAM_RUNTIME=1' \
        'export STEAM_RUNTIME_HEAVY=1' \
        'exec /usr/local/bin/steam "$@"' > /usr/local/bin/steam-pressure-vessel && \
    chmod -f 755 /usr/local/bin/steam && \
    chmod -f 755 /usr/local/bin/steam-pressure-vessel && \
    if [ -f /usr/share/applications/steam.desktop ]; then \
        sed -i 's#^Exec=.*#Exec=/usr/local/bin/steam %U#' /usr/share/applications/steam.desktop; \
        cp -f /usr/share/applications/steam.desktop /usr/share/applications/steam-pressure-vessel.desktop; \
        sed -i 's#^Name=.*#Name=Steam (Pressure Vessel)#' /usr/share/applications/steam-pressure-vessel.desktop; \
        sed -i 's#^Exec=.*#Exec=/usr/local/bin/steam-pressure-vessel %U#' /usr/share/applications/steam-pressure-vessel.desktop; \
    fi && \
    { [ -x /usr/games/steam ] || [ -x /usr/bin/steam ] || [ -x /usr/lib/steam/steam ] || [ -x /usr/lib/steam/steam.sh ]; } && \
    dpkg -s steam-launcher libstdc++6:i386 libgcc-s1:i386 libnss3:i386 libfontconfig1:i386 libfreetype6:i386 libgtk2.0-0:i386 libpipewire-0.3-0:i386 libxcb-res0:i386 >/dev/null 2>&1; fi && \
    if [ "${INSTALL_LIBREOFFICE}" = "1" ]; then \
    apt-get install --install-recommends -y \
        libreoffice \
        libreoffice-kf5 \
        libreoffice-plasma \
        libreoffice-style-breeze; fi && \
    # Ensure Firefox as the default web browser
    xdg-settings set default-web-browser firefox.desktop && \
    update-alternatives --set x-www-browser /usr/bin/firefox && \
    # Install Google Chrome for supported architectures
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then cd /tmp && curl -o google-chrome-stable.deb -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_$(dpkg --print-architecture).deb" && apt-get update && apt-get install --no-install-recommends -y ./google-chrome-stable.deb && rm -f google-chrome-stable.deb && sed -i '/^Exec=/ s/$/ --password-store=basic --in-process-gpu/' /usr/share/applications/google-chrome.desktop; fi && \
    fc-cache -f >/dev/null 2>&1 || true && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/* && \
    # Fix KDE startup permissions issues in containers
    MULTI_ARCH=$(dpkg --print-architecture | sed -e 's/arm64/aarch64-linux-gnu/' -e 's/armhf/arm-linux-gnueabihf/' -e 's/riscv64/riscv64-linux-gnu/' -e 's/ppc64el/powerpc64le-linux-gnu/' -e 's/s390x/s390x-linux-gnu/' -e 's/i.*86/i386-linux-gnu/' -e 's/amd64/x86_64-linux-gnu/' -e 's/unknown/x86_64-linux-gnu/') && \
    cp -f /usr/lib/${MULTI_ARCH}/libexec/kf5/start_kdeinit /tmp/ && \
    rm -f /usr/lib/${MULTI_ARCH}/libexec/kf5/start_kdeinit && \
    cp -f /tmp/start_kdeinit /usr/lib/${MULTI_ARCH}/libexec/kf5/start_kdeinit && \
    rm -f /tmp/start_kdeinit && \
    # KDE disable screen lock, double-click to open instead of single-click
    echo "[Daemon]\n\
Autolock=false\n\
LockOnResume=false" > /etc/xdg/kscreenlockerrc && \
    echo "[Compositing]\n\
Enabled=false" > /etc/xdg/kwinrc && \
    echo "[KDE]\n\
SingleClick=false\n\
\n\
[KDE Action Restrictions]\n\
action/lock_screen=false\n\
logout=false\n\
\n\
[General]\n\
BrowserApplication=firefox.desktop" > /etc/xdg/kdeglobals

RUN if [ "$(dpkg --print-architecture)" = "amd64" ] && [ "${INSTALL_STEAM}" = "1" ] && [ "${STEAM_PREBOOTSTRAP}" = "1" ]; then \
    STEAM_BOOT_HOME="/tmp/steam-bootstrap-home"; \
    STEAM_BOOT_RUNTIME="/tmp/steam-bootstrap-runtime"; \
    STEAM_BOOT_LOG="/tmp/steam-bootstrap.log"; \
    STEAM_BOOT_XVFB_LOG="/tmp/steam-bootstrap-xvfb.log"; \
    STEAM_BOOT_EXIT=0; \
    STEAM_SEED_OK=0; \
    rm -rf "${STEAM_SEED_ROOT}" "${STEAM_BOOT_HOME}" "${STEAM_BOOT_RUNTIME}"; \
    mkdir -pm755 "${STEAM_SEED_ROOT}"; \
    mkdir -pm700 "${STEAM_BOOT_HOME}" "${STEAM_BOOT_RUNTIME}"; \
    STEAM_BOOTSTRAP_SCRIPT='set -eu; export HOME=/tmp/steam-bootstrap-home; export XDG_RUNTIME_DIR=/tmp/steam-bootstrap-runtime; export DISPLAY=:98; mkdir -pm700 "$HOME" "$XDG_RUNTIME_DIR"; /usr/bin/Xvfb :98 -screen 0 1280x720x24 -nolisten tcp -ac -noreset >/tmp/steam-bootstrap-xvfb.log 2>&1 & xvfb_pid=$!; trap "kill $xvfb_pid >/dev/null 2>&1 || true" EXIT INT TERM; for i in $(seq 1 30); do [ -S /tmp/.X11-unix/X98 ] && break; sleep 1; done; timeout 300 /usr/local/bin/steam -silent +quit >/tmp/steam-bootstrap.log 2>&1 || true; pkill -x steamwebhelper >/dev/null 2>&1 || true; pkill -x steam >/dev/null 2>&1 || true; sleep 1'; \
    if command -v Xvfb >/dev/null 2>&1; then \
        if command -v dbus-run-session >/dev/null 2>&1; then \
            if dbus-run-session -- sh -lc "${STEAM_BOOTSTRAP_SCRIPT}"; then \
                STEAM_BOOT_EXIT=0; \
            else \
                STEAM_BOOT_EXIT=$?; \
                echo "WARNING: Steam prebootstrap command with dbus-run-session failed with exit code ${STEAM_BOOT_EXIT}."; \
            fi; \
        else \
            STEAM_BOOT_EXIT=127; \
            echo "WARNING: Steam prebootstrap is running without dbus-run-session."; \
        fi; \
        if [ ! -x "${STEAM_BOOT_HOME}/.steam/debian-installation/ubuntu12_32/steam" ]; then \
            if sh -lc "${STEAM_BOOTSTRAP_SCRIPT}"; then \
                STEAM_BOOT_EXIT=0; \
            else \
                STEAM_BOOT_EXIT=$?; \
                echo "WARNING: Steam prebootstrap fallback without dbus-run-session failed with exit code ${STEAM_BOOT_EXIT}."; \
            fi; \
        fi; \
    else \
        STEAM_BOOT_EXIT=127; \
        echo "WARNING: Steam prebootstrap skipped because Xvfb is missing."; \
    fi; \
    if [ -x "${STEAM_BOOT_HOME}/.steam/debian-installation/ubuntu12_32/steam" ]; then \
        mkdir -pm700 "${STEAM_SEED_ROOT}/.steam" "${STEAM_SEED_ROOT}/.local/share/Steam"; \
        cp -a "${STEAM_BOOT_HOME}/.steam/." "${STEAM_SEED_ROOT}/.steam/" || true; \
        if [ -d "${STEAM_BOOT_HOME}/.local/share/Steam" ]; then cp -a "${STEAM_BOOT_HOME}/.local/share/Steam/." "${STEAM_SEED_ROOT}/.local/share/Steam/" || true; fi; \
        rm -rf "${STEAM_SEED_ROOT}/.steam/steam/logs" "${STEAM_SEED_ROOT}/.steam/debian-installation/logs"; \
        if [ -x "${STEAM_SEED_ROOT}/.steam/debian-installation/ubuntu12_32/steam" ]; then \
            touch "${STEAM_SEED_ROOT}/.seed-ready"; \
            STEAM_SEED_OK=1; \
            echo "Steam prebootstrap seed created at ${STEAM_SEED_ROOT}"; \
        else \
            echo "WARNING: Steam prebootstrap produced partial files but seed validation failed."; \
        fi; \
    else \
        echo "WARNING: Steam prebootstrap ran but did not produce a full client tree."; \
    fi; \
    if [ "${STEAM_SEED_OK}" != "1" ] && [ "${STEAM_PREBOOTSTRAP_STRICT}" = "1" ]; then \
        echo "ERROR: Steam prebootstrap strict mode is enabled and no valid seed was produced."; \
        echo "HINT: inspect ${STEAM_BOOT_LOG} and ${STEAM_BOOT_XVFB_LOG} in the build output."; \
        exit 1; \
    fi; \
    rm -rf "${STEAM_BOOT_HOME}" "${STEAM_BOOT_RUNTIME}"; \
fi

# KDE environment variables
ENV DESKTOP_SESSION=plasma
ENV XDG_SESSION_DESKTOP=KDE
ENV XDG_CURRENT_DESKTOP=KDE
ENV XDG_SESSION_TYPE=x11
ENV KDE_FULL_SESSION=true
ENV KDE_SESSION_VERSION=5
ENV KDE_APPLICATIONS_AS_SCOPE=1
ENV KWIN_COMPOSE=N
ENV KWIN_EFFECTS_FORCE_ANIMATIONS=0
ENV KWIN_EXPLICIT_SYNC=0
ENV KWIN_X11_NO_SYNC_TO_VBLANK=1
# Use sudoedit to change protected files instead of using sudo on kwrite
ENV SUDO_EDITOR=kwrite
# Enable AppImage execution in containers
ENV APPIMAGE_EXTRACT_AND_RUN=1
# Set input to fcitx
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XIM=fcitx
ENV XMODIFIERS="@im=fcitx"

# Wine, Winetricks, and launchers, this process must be consistent with https://wiki.winehq.org/Ubuntu
ARG WINE_BRANCH=staging
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    mkdir -pm755 /etc/apt/keyrings && curl -fsSL -o /etc/apt/keyrings/winehq-archive.key "https://dl.winehq.org/wine-builds/winehq.key" && \
    curl -fsSL -o "/etc/apt/sources.list.d/winehq-$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"').sources" "https://dl.winehq.org/wine-builds/ubuntu/dists/$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"')/winehq-$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"').sources" && \
    apt-get update && apt-get install --install-recommends -y \
        winehq-${WINE_BRANCH} && \
    apt-get install --no-install-recommends -y \
        q4wine \
        playonlinux && \
    LUTRIS_VERSION="$(curl -fsSL "https://api.github.com/repos/lutris/lutris/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && curl -o lutris.deb -fsSL "https://github.com/lutris/lutris/releases/download/v${LUTRIS_VERSION}/lutris_${LUTRIS_VERSION}_all.deb" && apt-get install --no-install-recommends -y ./lutris.deb && rm -f lutris.deb && \
    HEROIC_VERSION="$(curl -fsSL "https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && curl -o heroic_launcher.deb -fsSL "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v${HEROIC_VERSION}/Heroic-${HEROIC_VERSION}-linux-$(dpkg --print-architecture).deb" && apt-get install --no-install-recommends -y ./heroic_launcher.deb && rm -f heroic_launcher.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/* && \
    curl -o /usr/bin/winetricks -fsSL "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" && \
    chmod -f 755 /usr/bin/winetricks && \
    curl -o /usr/share/bash-completion/completions/winetricks -fsSL "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion"; fi

# Install latest Selkies (https://github.com/selkies-project/selkies) build, Python application, and web application, should be consistent with Selkies documentation
ARG PIP_BREAK_SYSTEM_PACKAGES=1
RUN apt-get update && apt-get install --no-install-recommends -y \
        # GStreamer dependencies
        python3-pip \
        python3-dev \
        python3-gi \
        python3-setuptools \
        python3-wheel \
        libgcrypt20 \
        libgirepository-1.0-1 \
        glib-networking \
        libglib2.0-0 \
        libgudev-1.0-0 \
        alsa-utils \
        jackd2 \
        libjack-jackd2-0 \
        libpulse0 \
        libopus0 \
        libvpx-dev \
        x264 \
        x265 \
        libdrm2 \
        libegl1 \
        libgl1 \
        libopengl0 \
        libgles1 \
        libgles2 \
        libglvnd0 \
        libglx0 \
        wayland-protocols \
        libwayland-dev \
        libwayland-egl1 \
        wmctrl \
        xsel \
        xdotool \
        x11-utils \
        x11-xkb-utils \
        x11-xserver-utils \
        xserver-xorg-core \
        libx11-xcb1 \
        libxcb-dri3-0 \
        libxdamage1 \
        libxfixes3 \
        libxv1 \
        libxtst6 \
        libxext6 && \
    if [ "$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"')" \> "20.04" ]; then apt-get install --no-install-recommends -y xcvt libopenh264-dev svt-av1 aom-tools; else apt-get install --no-install-recommends -y mesa-utils-extra; fi && \
    # Automatically fetch the latest Selkies version and install the components
    SELKIES_VERSION="$(curl -fsSL "https://api.github.com/repos/selkies-project/selkies/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /opt && curl -fsSL "https://github.com/selkies-project/selkies/releases/download/v${SELKIES_VERSION}/gstreamer-selkies_gpl_v${SELKIES_VERSION}_ubuntu$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"')_$(dpkg --print-architecture).tar.gz" | tar -xzf - && \
    cd /tmp && curl -O -fsSL "https://github.com/selkies-project/selkies/releases/download/v${SELKIES_VERSION}/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && pip3 install --no-cache-dir --force-reinstall "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" "websockets<14.0" && rm -f "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && \
    cd /opt && curl -fsSL "https://github.com/selkies-project/selkies/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-web_v${SELKIES_VERSION}.tar.gz" | tar -xzf - && \
    cd /tmp && curl -o selkies-js-interposer.deb -fsSL "https://github.com/selkies-project/selkies/releases/download/v${SELKIES_VERSION}/selkies-js-interposer_v${SELKIES_VERSION}_ubuntu$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"')_$(dpkg --print-architecture).deb" && apt-get update && apt-get install --no-install-recommends -y ./selkies-js-interposer.deb && rm -f selkies-js-interposer.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*

# Install the KasmVNC web interface and RustDesk for fallback
RUN KASMVNC_VERSION="$(curl -fsSL "https://api.github.com/repos/kasmtech/KasmVNC/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && curl -o kasmvncserver.deb -fsSL "https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/kasmvncserver_$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"')_${KASMVNC_VERSION}_$(dpkg --print-architecture).deb" && apt-get update && apt-get install --no-install-recommends -y ./kasmvncserver.deb libdatetime-perl && rm -f kasmvncserver.deb && \
    RUSTDESK_VERSION="$(curl -fsSL "https://api.github.com/repos/rustdesk/rustdesk/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && curl -o rustdesk.deb -fsSL "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-$(uname -m).deb" && apt-get update && apt-get install --no-install-recommends -y ./rustdesk.deb && rm -f rustdesk.deb && \
    YQ_VERSION="$(curl -fsSL "https://api.github.com/repos/mikefarah/yq/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && curl -o yq -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(dpkg --print-architecture)" && install ./yq /usr/bin/ && rm -f yq && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*
ENV PATH="${PATH:+${PATH}:}/usr/lib/rustdesk"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}/usr/lib/rustdesk/lib"

# Add custom packages right below this comment, or use FROM in a new container and replace entrypoint.sh or supervisord.conf, and set ENTRYPOINT to /usr/bin/supervisord

# Copy scripts and configurations used to start the container with `--chown=1000:1000`
COPY --chown=1000:1000 entrypoint.sh /etc/entrypoint.sh
RUN chmod -f 755 /etc/entrypoint.sh
COPY --chown=1000:1000 selkies-gstreamer-entrypoint.sh /etc/selkies-gstreamer-entrypoint.sh
RUN chmod -f 755 /etc/selkies-gstreamer-entrypoint.sh
COPY --chown=1000:1000 kasmvnc-entrypoint.sh /etc/kasmvnc-entrypoint.sh
RUN chmod -f 755 /etc/kasmvnc-entrypoint.sh
COPY --chown=1000:1000 supervisord.conf /etc/supervisord.conf
RUN chmod -f 755 /etc/supervisord.conf

# Configure coTURN script
RUN echo "#!/bin/bash\n\
set -e\n\
turnserver \
    --verbose \
    --listening-ip=\"0.0.0.0\" \
    --listening-ip=\"::\" \
    --listening-port=\"\${SELKIES_TURN_PORT:-3478}\" \
    --realm=\"\${TURN_REALM:-example.com}\" \
    --external-ip=\"\${TURN_EXTERNAL_IP:-\$(dig -4 TXT +short @ns1.google.com o-o.myaddr.l.google.com 2>/dev/null | { read output; if [ -z \"\$output\" ] || echo \"\$output\" | grep -q '^;;'; then exit 1; else echo \"\$(echo \$output | sed 's,\\\",,g')\"; fi } || dig -6 TXT +short @ns1.google.com o-o.myaddr.l.google.com 2>/dev/null | { read output; if [ -z \"\$output\" ] || echo \"\$output\" | grep -q '^;;'; then exit 1; else echo \"[\$(echo \$output | sed 's,\\\",,g')]\"; fi } || hostname -I 2>/dev/null | awk '{print \$1; exit}' || echo '127.0.0.1')}\" \
    --min-port=\"\${TURN_MIN_PORT:-49152}\" \
    --max-port=\"\${TURN_MAX_PORT:-65535}\" \
    --channel-lifetime=\"\${TURN_CHANNEL_LIFETIME:--1}\" \
    --lt-cred-mech \
    --user=\"selkies:\${TURN_RANDOM_PASSWORD:-\$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 24)}\" \
    --no-cli \
    --cli-password=\"\${TURN_RANDOM_PASSWORD:-\$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 24)}\" \
    --userdb=\"\${XDG_RUNTIME_DIR:-/tmp}/turnserver-turndb\" \
    --pidfile=\"\${XDG_RUNTIME_DIR:-/tmp}/turnserver.pid\" \
    --log-file=\"stdout\" \
    --allow-loopback-peers \
    \${TURN_EXTRA_ARGS} \$@\
" > /etc/start-turnserver.sh && chmod -f 755 /etc/start-turnserver.sh

SHELL ["/bin/sh", "-c"]

USER 0
# Enable sudo through sudo-root with uid 0
RUN if [ -d "/usr/libexec/sudo" ]; then SUDO_LIB="/usr/libexec/sudo"; else SUDO_LIB="/usr/lib/sudo"; fi && \
    chown -R -f -h --no-preserve-root root:root /usr/bin/sudo-root /etc/sudo.conf /etc/sudoers /etc/sudoers.d /etc/sudo_logsrvd.conf "${SUDO_LIB}" || echo 'Failed to provide root permissions in some paths relevant to sudo' && \
    chmod -f 4755 /usr/bin/sudo-root && \
    for helper in /usr/bin/pkexec /usr/lib/polkit-1/polkit-agent-helper-1 /usr/bin/bwrap; do \
        if [ -e "${helper}" ]; then \
            chown -f root:root "${helper}" || true; \
            chmod -f 4755 "${helper}" || true; \
        fi; \
    done || echo 'Failed to restore setuid root on Steam helpers'
USER 1000

ENV PIPEWIRE_LATENCY="128/48000"
ENV XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
ENV PIPEWIRE_RUNTIME_DIR="${PIPEWIRE_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/tmp}}"
ENV PULSE_RUNTIME_PATH="${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}"
ENV PULSE_SERVER="${PULSE_SERVER:-unix:${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}/native}"

# dbus-daemon to the below address is required during startup
ENV DBUS_SYSTEM_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR:-/tmp}/dbus-system-bus"

USER 1000
ENV SHELL=/bin/bash
ENV USER=ubuntu
ENV HOME=/home/ubuntu
WORKDIR /home/ubuntu

EXPOSE 8080

ENTRYPOINT ["/usr/bin/supervisord"]
