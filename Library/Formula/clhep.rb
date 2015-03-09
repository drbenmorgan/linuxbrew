class Clhep < Formula
  homepage "http://proj-clhep.web.cern.ch/proj-clhep/"
  url "http://proj-clhep.web.cern.ch/proj-clhep/DISTRIBUTION/tarFiles/clhep-2.2.0.4.tgz"
  sha1 "60a291b940fdc78bea4aaeaffc147cc25a42cfef"

  bottle do
    cellar :any
    sha1 "5466fbee57b366a41bbcec814614ee236e39bed8" => :yosemite
    sha1 "bde270764522e4a1d99767ca759574a99485e5ac" => :mavericks
    sha1 "e77d0e5f516cb41ac061e1050c8f37d0fb65b796" => :mountain_lion
  end

  depends_on "cmake" => :build
  option :cxx11

  def install
    ENV.cxx11 if build.cxx11?
    mkdir "clhep-build" do
      args = std_cmake_args
      args << "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
      args << "-DCLHEP_BUILD_CXXSTD=c++11" if build.cxx11?
      system "cmake", "../CLHEP", *args
      system "make", "install"
    end
  end
end
