class CIRequirement < Requirement
  fatal true
  satisfy { ENV["CIRCLECI"].nil? && ENV["TRAVIS"].nil? }
end

class Crystal < Formula
  desc "Fast and statically typed, compiled language with Ruby-like syntax"
  homepage "https://crystal-lang.org/"

  stable do
    url "https://github.com/crystal-lang/crystal/archive/0.27.2.tar.gz"
    sha256 "d2fe8a025668b143e8ff70b3cd407765140ed10e52523dd08253139f9322171b"

    resource "shards" do
      url "https://github.com/crystal-lang/shards/archive/v0.8.1.tar.gz"
      sha256 "75c74ab6acf2d5c59f61a7efd3bbc3c4b1d65217f910340cb818ebf5233207a5"
    end
  end

  bottle do
    cellar :any
    sha256 "d2af850ac6832460a4f88d9788cd205412a73e5f0807e27b61b7bb3c39c2f0cd" => :mojave
    sha256 "1274def6adff3b374aa5a4eeba12ac1664e3cd1405036c288834cd7ad2599071" => :high_sierra
    sha256 "02804838a14b4c196ea615d3813cad05d912d09d85a4920a894e2e1ef9ed5bf1" => :sierra
  end

  head do
    url "https://github.com/crystal-lang/crystal.git"

    resource "shards" do
      url "https://github.com/crystal-lang/shards.git"
    end
  end

  depends_on "libatomic_ops" => :build # for building bdw-gc
  depends_on "bdw-gc"
  depends_on CIRequirement
  depends_on "gmp" # std uses it but it's not linked
  depends_on "libevent"
  depends_on "libyaml"
  depends_on "llvm@6"
  depends_on "pcre"
  depends_on "pkg-config" # @[Link] will use pkg-config if available

  resource "boot" do
    if OS.mac?
      url "https://github.com/crystal-lang/crystal/releases/download/0.27.1/crystal-0.27.1-1-darwin-x86_64.tar.gz"
      version "0.27.1-1"
      sha256 "f5102f34b6801a1bae3afe66fb6da15308cc304c3a9fba5799f4379c1e3010b1"
    else
      url "https://github.com/crystal-lang/crystal/releases/download/0.27.1/crystal-0.27.1-1-linux-x86_64.tar.gz"
      version "0.27.1-1"
      sha256 "6fc9bf01f0c74d754e01c68bda8a96d59cebbee49dd09c4dc93050d7a1e967ca"
    end
  end

  def install
    (buildpath/"boot").install resource("boot")

    if build.head?
      ENV["CRYSTAL_CONFIG_BUILD_COMMIT"] = Utils.popen_read("git rev-parse --short HEAD").strip
    end

    ENV["CRYSTAL_CONFIG_PATH"] = prefix/"src:lib"
    ENV.append_path "PATH", "boot/bin"

    system "make", "deps"
    (buildpath/".build").mkpath

    system "bin/crystal", "build",
                          "-D", "without_openssl",
                          "-D", "without_zlib",
                          "-D", "preview_overflow",
                          "-o", ".build/crystal",
                          "src/compiler/crystal.cr",
                          "--release", "--no-debug"

    resource("shards").stage do
      system buildpath/"bin/crystal", "build", "-o", buildpath/".build/shards", "src/shards.cr"
    end

    bin.install ".build/shards"
    bin.install ".build/crystal"
    prefix.install "src"
    bash_completion.install "etc/completion.bash" => "crystal"
    zsh_completion.install "etc/completion.zsh" => "_crystal"
  end

  test do
    assert_match "1", shell_output("#{bin}/crystal eval puts 1")
  end
end
