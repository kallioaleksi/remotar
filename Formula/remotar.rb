class Remotar < Formula
  desc "Pipe a tar stream over SSH to fetch or push directories"
  homepage "https://github.com/kallioaleksi/remotar"
  url "https://github.com/kallioaleksi/remotar/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "c0d9e40023571ac99c6afed29da8614aebb6d117e3a8e8b52ff6bac8c3699efb"
  license "MIT"
  head "https://github.com/kallioaleksi/remotar.git", branch: "main"

  def install
    bin.install "bin/remotar"
  end

  def caveats
    <<~EOS
      Optional tools for flags:
        -z requires zstd on both ends:  brew install zstd
        -p requires pv locally:         brew install pv
    EOS
  end

  test do
    assert_match "remotar", shell_output("#{bin}/remotar --version")
    assert_match "Usage", shell_output("#{bin}/remotar --help")
  end
end
