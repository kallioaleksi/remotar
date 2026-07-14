class Remotar < Formula
  desc "Pipe a tar stream over SSH to fetch or push directories"
  homepage "https://github.com/kallioaleksi/remotar"
  url "https://github.com/kallioaleksi/remotar/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # replaced after tagging
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
