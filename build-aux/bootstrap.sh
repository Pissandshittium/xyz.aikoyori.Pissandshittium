#!/bin/bash -ex

export CC="/app/bin/sccache gcc"
# Needed to build GN itself.
. /usr/lib/sdk/llvm14/enable.sh

# GN will use these variables to configure its own build, but they introduce
# compat issues w/ Clang and aren't used by Chromium itself anyway, so just
# unset them here.
unset CFLAGS CXXFLAGS LDFLAGS


if [[ -d third_party/llvm-build/Release+Asserts/bin ]]; then
  # The build scripts check that the stamp file is present, so write it out
  # here.
  PYTHONPATH=tools/clang/scripts/ \
    python3 -c 'import update; print(update.PACKAGE_VERSION)' \
    > third_party/llvm-build/Release+Asserts/cr_build_revision
else
  python3 tools/clang/scripts/build.py --disable-asserts \
      --skip-checkout --use-system-cmake --use-system-libxml \
      --host-cc=/usr/lib/sdk/llvm14/bin/clang \
      --host-cxx=/usr/lib/sdk/llvm14/bin/clang++ \
      --target-triple=$(clang -dumpmachine) \
      --without-android --without-fuchsia --without-zstd \
      --with-ml-inliner-model=
fi

# (TODO: enable use_qt in the future?)
# dbus disabled for now
# DO NOT REUSE THE BELOW API KEY; it is for Flathub only.
# http://lists.debian.org/debian-legal/2013/11/msg00006.html
tools/gn/bootstrap/bootstrap.py -v --no-clean --gn-gen-args='
    use_sysroot=false
    use_lld=true
    enable_nacl=false
    blink_symbol_level=0
    use_gnome_keyring=false
    use_pulseaudio=true
    clang_use_chrome_plugins=false
    is_official_build=true
    google_api_key="AIzaSyAfm3u8ajPiclARl850n0pXUXbTb4LRSvk"
    google_default_client_id = "971968280473-uri1d0skuvrl7eo0h3c65l7nsnjgp1ku.apps.googleusercontent.com"
    google_default_client_secret = "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"
    treat_warnings_as_errors=false
    proprietary_codecs=true
    ffmpeg_branding="Chrome"
    is_component_ffmpeg=true
    use_vaapi=true
    enable_widevine=true
    rtc_use_pipewire=true
    rtc_link_pipewire=true
    enable_hangout_services_extension=true
    disable_fieldtrial_testing_config=true
    use_system_libwayland=false
    use_system_libffi=true
    use_qt=false
    enable_remoting=false
    enable_rust=false
    cc_wrapper = "sccache"
    clang_use_chrome_plugins = false
    treat_warnings_as_errors=false
    use_dbus=false
'
mkdir -p out/ReleaseFree
cp out/Release{,Free}/args.gn
echo -e 'proprietary_codecs = false\nffmpeg_branding = "Chromium"' >> out/ReleaseFree/args.gn
out/Release/gn gen out/ReleaseFree
