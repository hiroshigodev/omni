class Omni < Formula
  desc "Semantic Distillation Engine for the Agentic Era"
  homepage "https://github.com/fajarhide/omni"
  url "https://github.com/fajarhide/omni/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "3d6231e1fbcf2e94b55f615de732b77062687f1186a055182ca0a72aee8f0da6"
  license "MIT"

  depends_on "zig" => :build
  depends_on "node"

  def install
    # Run builds from the 'core' directory
    Dir.chdir("core") do
      # Native binary -> bin/omni
      system "zig", "build", "-Doptimize=ReleaseFast", "-Dversion=#{version}", "-p", "../"
      # Wasm binary -> bin/omni-wasm.wasm
      system "zig", "build", "wasm", "-Doptimize=ReleaseSmall", "-Dversion=#{version}", "-p", "../"
    end

    # Install Native Binary
    bin.install "bin/omni"

    # Install Wasm Binary
    (lib/"omni").install "bin/omni-wasm.wasm"

    # Install MCP Server
    # Use plain local npm install so devDeps (typescript/tsc) are available for build
    libexec.install "package.json", "src"
    cd libexec do
      system "npm", "install"
      system "./node_modules/.bin/tsc"
      system "npm", "prune", "--omit=dev"
    end
    # Create a wrapper for the MCP server
    (bin/"omni-mcp").write <<~EOS
      #!/bin/bash
      export OMNI_WASM_PATH="#{lib}/omni/omni-wasm.wasm"
      node "#{libexec}/dist/index.js" "$@"
    EOS
  end

  test do
    assert_match "omni", shell_output("#{bin}/omni --help")
  end
end
