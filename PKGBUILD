# Maintainer: Mike Pevzner <mike.pevzner@pm.me>

pkgname=omarchy-transcribe
pkgver=0.1.0
pkgrel=1
pkgdesc="Transcribe videos and audio to SRT with whisper.cpp from the Omarchy menu and Nautilus"
arch=(any)
url="https://github.com/mikepevzner/omarchy-transcribe"
license=(MIT)
depends=(bash omarchy whisper-cpp nautilus-python gum curl file)
optdepends=('ggml-vulkan: GPU-accelerated transcription')
install=omarchy-transcribe.install

# Built straight from the checkout: run `makepkg -si` in the repo root. There is
# no source=() because the files are right here; switch to a git source when
# publishing to the AUR.

package() {
  cd "$startdir"

  install -Dm755 -t "$pkgdir/usr/bin" \
    bin/omarchy-transcribe \
    bin/omarchy-transcribe-install \
    bin/omarchy-transcribe-remove

  install -Dm644 -t "$pkgdir/usr/share/nautilus-python/extensions" \
    nautilus/omarchy-transcribe.py

  install -Dm644 default/config "$pkgdir/usr/share/omarchy-transcribe/config"

  install -Dm644 -t "$pkgdir/usr/share/licenses/$pkgname" LICENSE
  install -Dm644 -t "$pkgdir/usr/share/doc/$pkgname" README.md
}
