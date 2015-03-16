class Root6 < Formula
  homepage "http://root.cern.ch"
  version "6.02.05"
  url "http://root.cern.ch/download/root_v#{version}.source.tar.gz"
  mirror "https://fossies.org/linux/misc/root_v#{version}.source.tar.gz"
  sha1 "3cec8b763d8c1ddfd80b41983000359704f16e1e"
  head "http://root.cern.ch/git/root.git"

  patch :DATA

  bottle do
    root_url "https://homebrew.bintray.com/bottles-science"
    sha1 "1689e8f11a5b54c2c4fb0a0e397037cb0581bef4" => :yosemite
    sha1 "a33bfe58e62c6ab19550c638b6cace609a1fe86d" => :mavericks
    sha1 "77907f45cc903d5bbcb6458e2687cffed21eab96" => :mountain_lion
  end

  depends_on "cmake" => :build
  depends_on "xrootd" => :optional
  depends_on "openssl" => :optional
  depends_on :python => :recommended
  depends_on :x11 => :recommended if OS.linux?

  needs :cxx11

  def cmake_opt(opt, pkg = opt)
    "-D#{opt}=#{(build.with? pkg) ? "ON" : "OFF"}"
  end

  def install
    # brew audit doesn't like non-executables in bin
    # so we will move {thisroot,setxrd}.{c,}sh to libexec
    # (and change any references to them)
    inreplace Dir["config/roots.in", "config/thisroot.*sh",
                  "etc/proof/utils/pq2/setup-pq2",
                  "man/man1/setup-pq2.1", "README/INSTALL", "README/README"],
      /bin.thisroot/, "libexec/thisroot"

    # Prevent collision with brewed freetype
    inreplace "graf2d/freetype/CMakeLists.txt", /install\(/, "#install("
    # xrootd: Workaround for
    # TXNetFile.cxx:64:10: fatal error: 'XpdSysPthread.h' file not found
    # this seems to be related to homebrew superenv
    inreplace "net/netx/CMakeLists.txt",
      /include_directories\(/, "\\0${CMAKE_SOURCE_DIR}/proof/proofd/inc "

    mkdir "cmake-build" do
      system "cmake", "..", 
        "-Dgnuinstall=ON",
        "-Dexplicitlink=ON",
        "-Drpath=ON",
        "-Dsoversion=ON",
        "-Dbuiltin_freetype=ON",
        cmake_opt("python"),
        cmake_opt("ssl", "openssl"),
        cmake_opt("xrootd"),
        *std_cmake_args
      system "make", "install"
    end

    libexec.mkpath
    mv Dir["#{bin}/*.*sh"], libexec
  end

  test do
    (testpath/"test.C").write <<-EOS.undent
      #include <iostream>
      void test() {
        std::cout << "Hello, world!" << std::endl;
      }
    EOS
    (testpath/"test.bash").write <<-EOS.undent
      . #{libexec}/thisroot.sh
      root -l -b -n -q test.C
    EOS
    assert_equal "\nProcessing test.C...\nHello, world!\n",
      `/bin/bash test.bash`
  end

  def caveats; <<-EOS.undent
    Because ROOT depends on several installation-dependent
    environment variables to function properly, you should
    add the following commands to your shell initialization
    script (.bashrc/.profile/etc.), or call them directly
    before using ROOT.

    For bash users:
      . $(brew --prefix root6)/libexec/thisroot.sh
    For zsh users:
      pushd $(brew --prefix root6) >/dev/null; . libexec/thisroot.sh; popd >/dev/null
    For csh/tcsh users:
      source `brew --prefix root6`/libexec/thisroot.csh
    EOS
  end
end
__END__
diff --git a/cmake/modules/RootBuildOptions.cmake b/cmake/modules/RootBuildOptions.cmake
index 81b6bf8..f42ef4e 100644
--- a/cmake/modules/RootBuildOptions.cmake
+++ b/cmake/modules/RootBuildOptions.cmake
@@ -183,21 +183,6 @@ option(all "Enable all optional components" OFF)
 option(testing "Enable testing with CTest" OFF)
 option(roottest "Include roottest, if roottest exists in root or if it is a sibling directory." OFF)
 
-#---General Build options----------------------------------------------------------------------
-# use, i.e. don't skip the full RPATH for the build tree
-set(CMAKE_SKIP_BUILD_RPATH  FALSE)
-# when building, don't use the install RPATH already (but later on when installing)
-set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
-# add the automatically determined parts of the RPATH
-# which point to directories outside the build tree to the install RPATH
-set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
-
-# the RPATH to be used when installing---------------------------------------------------------
-if(rpath)
-  set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
-  set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
-endif()
-
 #---Avoid creating dependencies to 'non-statndard' header files -------------------------------
 include_regular_expression("^[^.]+$|[.]h$|[.]icc$|[.]hxx$|[.]hpp$")
 
@@ -212,5 +197,20 @@ endif()
 #---Add Installation Variables------------------------------------------------------------------
 include(RootInstallDirs)
 
+#---General Build options----------------------------------------------------------------------
+# use, i.e. don't skip the full RPATH for the build tree
+set(CMAKE_SKIP_BUILD_RPATH  FALSE)
+# when building, don't use the install RPATH already (but later on when installing)
+set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
+# add the automatically determined parts of the RPATH
+# which point to directories outside the build tree to the install RPATH
+set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
+
+# the RPATH to be used when installing---------------------------------------------------------
+if(rpath)
+  set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_FULL_LIBDIR}")
+  set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
+endif()
+


