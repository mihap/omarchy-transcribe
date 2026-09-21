# Maintainer: Mike Pevzner <mike.pevzner@pm.me>

pkgname=omarchy-transcribe
pkgver=0.4.0
pkgrel=1
pkgdesc="Transcribe videos and audio to SRT with whisper.cpp from the Omarchy menu and Nautilus"
arch=(any)
url="https://github.com/mihap/omarchy-transcribe"
license=(MIT)
depends=(bash omarchy whisper-cpp curl file)
optdepends=(
  'nautilus-python: right-click Transcribe entry in Files'
  'ggml-vulkan: GPU-accelerated transcription'
)
makedepends=(git)
install=omarchy-transcribe.install
# The source is this very checkout, so `makepkg -si` in the repo root builds
# whatever is committed on the current branch (commit first). makepkg reuses
# an existing package file of the same version instead of rebuilding, so bump
# pkgver/pkgrel for every change, or run `makepkg -sif` to force. For an AUR
# release, point this at the public git URL with a tag fragment instead.
source=("$pkgname::git+file://$startdir")
sha256sums=(SKIP)

package() {
  cd "$srcdir/$pkgname"

  install -Dm755 -t "$pkgdir/usr/bin" \
    bin/omarchy-transcribe \
    bin/omarchy-transcribe-install \
    bin/omarchy-transcribe-remove \
    bin/omarchy-transcribe-menu

  install -Dm644 -t "$pkgdir/usr/share/nautilus-python/extensions" \
    nautilus/omarchy-transcribe.py

  install -Dm644 default/config "$pkgdir/usr/share/omarchy-transcribe/config"

  install -Dm644 -t "$pkgdir/usr/share/licenses/$pkgname" LICENSE
  install -Dm644 -t "$pkgdir/usr/share/doc/$pkgname" README.md
}
