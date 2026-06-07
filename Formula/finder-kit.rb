# Template Homebrew (ajuste tap/user antes de publicar).
# Uso local: brew install --build-from-source ./Formula/finder-kit.rb
class FinderKit < Formula
  desc "Extensões utilitárias para o Finder (tamanho de pasta, etc.)"
  homepage "https://github.com/alexandrehpiva/finder-kit"
  version "1.0.0"
  url "https://github.com/alexandrehpiva/finder-kit/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "" # preencher após primeiro release
  license :cannot_represent

  depends_on :xcode => ["15.0", :build]
  depends_on "xcodegen" => :build

  def install
    system "make", "install", "PREFIX=#{prefix}"
    # Alternativa: empacotar só o .app em libexec e linkar CLI em bin/
  end

  test do
    system "#{bin}/finder-kit", "analyze", testpath.to_s
  end
end
