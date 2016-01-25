class Tbb < Formula
  desc "Rich and complete approach to parallelism in C++"
  homepage "https://www.threadingbuildingblocks.org/"
  url "https://www.threadingbuildingblocks.org/sites/default/files/software_releases/source/tbb44_20150728oss_src.tgz"
  sha256 "e9534f3238e6f7b34f9d0a78cb8604da1c5a611c5a2569fdd9cc90e06339538a"
  version "4.4-20150728"

  patch :DATA

  bottle do
    cellar :any
    sha256 "b11025b78347ee6fb889742421bb565df55634c29e5c86eda7999587462d7a60" => :el_capitan
    sha256 "926ffaf0439792e21854d37bea69409eeb4cbb071da4e06ae6e0c41e7bc2141a" => :yosemite
    sha256 "f22cef18da392b3b6c61d830e30d9156123b5b8474b51315dc46ff6aafbb002d" => :mavericks
  end

  # requires malloc features first introduced in Lion
  # https://github.com/Homebrew/homebrew/issues/32274
  depends_on :macos => :lion

  option :cxx11

  def install
    # Intel sets varying O levels on each compile command.
    ENV.no_optimization

    args = %W[tbb_build_prefix=BUILDPREFIX]

    if build.cxx11?
      ENV.cxx11
      args << "cpp0x=1"
      args << "stdlib=libc++" if OS.mac?
    end

    system "make", *args
    if OS.mac?
      lib.install Dir["build/BUILDPREFIX_release/*.dylib"]
    else
      lib.install Dir["build/BUILDPREFIX_release/*.so*"]
    end
    include.install "include/tbb"
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <tbb/task_scheduler_init.h>
      #include <iostream>

      int main()
      {
        std::cout << tbb::task_scheduler_init::default_num_threads();
        return 0;
      }
    EOS
    system ENV.cxx, "test.cpp", "-ltbb", "-o", "test"
    system "./test"
  end
end
__END__
diff --git a/build/linux.gcc.inc b/build/linux.gcc.inc
index 4b7122b..37f4c4c 100644
--- a/build/linux.gcc.inc
+++ b/build/linux.gcc.inc
@@ -32,8 +32,8 @@ DYLIB_KEY = -shared
 EXPORT_KEY = -Wl,--version-script,
 LIBDL = -ldl
 
-CPLUS = g++
-CONLY = gcc
+CPLUS = $(CXX)
+CONLY = $(CC)
 LIB_LINK_FLAGS = $(DYLIB_KEY) -Wl,-soname=$(BUILDING_LIBRARY)
 LIBS += -lpthread -lrt
 LINK_FLAGS = -Wl,-rpath-link=. -rdynamic
diff --git a/build/linux.inc b/build/linux.inc
index 631c520..bc701e1 100644
--- a/build/linux.inc
+++ b/build/linux.inc
@@ -57,7 +57,7 @@ ifndef arch
 endif
 
 ifndef runtime
-        gcc_version:=$(shell gcc -dumpversion)
+        gcc_version:=$(shell $(CC) -dumpversion)
         os_version:=$(shell uname -r)
         os_kernel_version:=$(shell uname -r | sed -e 's/-.*$$//')
         export os_glibc_version_full:=$(shell getconf GNU_LIBC_VERSION | grep glibc | sed -e 's/^glibc //')
