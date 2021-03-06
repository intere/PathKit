import Foundation
import Spectre
import PathKit


describe("PathKit") {
  let fixtures = Path(#file).parent() + "Fixtures"

  $0.before {
    Path.current = Path(#file).parent()
  }

  $0.it("provides the system separator") {
    try expect(Path.separator) == "/"
  }

  $0.it("returns the current working directory") {
    try expect(Path.current.description) == NSFileManager().currentDirectoryPath
  }

  $0.describe("initialisation") {
    $0.it("can be initialised with no arguments") {
      try expect(Path().description) == ""
    }

    $0.it("can be initialised with a string") {
      let path = Path("/usr/bin/swift")
      try expect(path.description) == "/usr/bin/swift"
    }

    $0.it("can be initialised with path components") {
      let path = Path(components: ["/usr", "bin", "swift"])
      try expect(path.description) == "/usr/bin/swift"
    }
  }

  $0.describe("convertable") {
    $0.it("can be converted from a string literal") {
      let path: Path = "/usr/bin/swift"
      try expect(path.description) == "/usr/bin/swift"
    }

    $0.it("can be converted to a string") {
      try expect(Path("/usr/bin/swift").description) == "/usr/bin/swift"
    }
  }

  $0.describe("Equatable") {
    $0.it("equates to an equal path") {
      try expect(Path("/usr")) == Path("/usr")
    }

    $0.it("doesn't equate to a non-equal path") {
      try expect(Path("/usr")) != Path("/bin")
    }
  }

  $0.describe("Hashable") {
    $0.it("exposes a hash value identical to an identical path") {
      try expect(Path("/usr").hashValue) == Path("/usr").hashValue
    }
  }

  $0.context("Absolute") {
    $0.describe("a relative path") {
      let path = Path("swift")

      $0.it("can be converted to an absolute path") {
        try expect(path.absolute()) == (Path.current + Path("swift"))
      }

      $0.it("is not absolute") {
        try expect(path.isAbsolute) == false
      }

      $0.it("is relative") {
        try expect(path.isRelative) == true
      }
    }

    $0.describe("an absolute path") {
      let path = Path("/usr/bin/swift")

      $0.it("can be converted to an absolute path") {
        try expect(path.absolute()) == path
      }

      $0.it("is absolute") {
        try expect(path.isAbsolute) == true
      }

      $0.it("is not relative") {
        try expect(path.isRelative) == false
      }
    }
  }

  $0.it("can be normalized") {
    let path = Path("/usr/./local/../bin/swift")
    try expect(path.normalize()) == Path("/usr/bin/swift")
  }

  $0.it("can be abbreviated") {
    let path = Path("/Users/\(NSUserName())/Library")
    try expect(path.abbreviate()) == Path("~/Library")
  }

  $0.describe("symlinking") {
    $0.it("can create a symlink with a relative destination") {
      let path = fixtures + "symlinks/file"
      let resolvedPath = try path.symlinkDestination()
      try expect(resolvedPath.normalize()) == fixtures + "file"
    }

    $0.it("can create a symlink with an absolute destination") {
      let path = fixtures + "symlinks/swift"
      let resolvedPath = try path.symlinkDestination()
      try expect(resolvedPath) == Path("/usr/bin/swift")
    }

    $0.it("can create a relative symlink in the same directory") {
      let path = fixtures + "symlinks/same-dir"
      let resolvedPath = try path.symlinkDestination()
      try expect(resolvedPath.normalize()) == fixtures + "symlinks/file"
    }
  }

  $0.it("can return the last component") {
    try expect(Path("a/b/c.d").lastComponent) == "c.d"
    try expect(Path("a/..").lastComponent) == ".."
  }

  $0.it("can return the last component without extension") {
    try expect(Path("a/b/c.d").lastComponentWithoutExtension) == "c"
    try expect(Path("a/..").lastComponentWithoutExtension) == "."
  }

  $0.it("can be split into components") {
    try expect(Path("a/b/c.d").components) == ["a", "b", "c.d"]
    try expect(Path("/a/b/c.d").components) == ["/", "a", "b", "c.d"]
    try expect(Path("~/a/b/c.d").components) == ["~", "a", "b", "c.d"]
  }

  $0.it("can return the extension") {
    try expect(Path("a/b/c.d").`extension`) == "d"
    try expect(Path("a/b.c.d").`extension`) == "d"
    try expect(Path("a/b").`extension`).to.beNil()
  }

  $0.describe("exists") {
    $0.it("can check if the path exists") {
      try expect(fixtures.exists).to.beTrue()
    }

    $0.it("can check if a path does not exist") {
      let path = Path("/pathkit/test")
      try expect(path.exists).to.beFalse()
    }
  }

  $0.describe("file info") {
    $0.it("can test if a path is a directory") {
      try expect((fixtures + "directory").isDirectory).to.beTrue()
      try expect((fixtures + "symlinks/directory").isDirectory).to.beTrue()
    }

    $0.it("can test if a path is a symlink") {
      try expect((fixtures + "file/file").isSymlink).to.beFalse()
      try expect((fixtures + "symlinks/file").isSymlink).to.beTrue()
    }

    $0.it("can test if a path is a file") {
      try expect((fixtures + "file").isFile).to.beTrue()
      try expect((fixtures + "symlinks/file").isFile).to.beTrue()
    }

    $0.it("can test if a path is executable") {
      try expect((fixtures + "permissions/executable").isExecutable).to.beTrue()
    }

    $0.it("can test if a path is readable") {
      try expect((fixtures + "permissions/readable").isReadable).to.beTrue()
    }

    $0.it("can test if a path is writable") {
      try expect((fixtures + "permissions/writable").isWritable).to.beTrue()
    }

    $0.it("can test if a path is deletable") {
      try expect((fixtures + "permissions/deletable").isDeletable).to.beTrue()
    }
  }

  $0.describe("changing directory") {
    $0.it("can change directory") {
      let current = Path.current

      try Path("/usr/bin").chdir {
        try expect(Path.current) == Path("/usr/bin")
      }

      try expect(Path.current) == current
    }

    $0.it("can change directory with a throwing closure") {
      let current = Path.current

      let error = NSError(domain: "org.cocode.PathKit", code: 1, userInfo: nil)
      try expect {
        try Path("/usr/bin").chdir {
          try expect(Path.current) == Path("/usr/bin")
          throw error
        }
      }.toThrow(error)

      try expect(Path.current) == current
    }
  }

  $0.describe("special paths") {
    $0.it("can provide the home directory") {
      try expect(Path.home) == Path("~").normalize()
    }

    $0.it("can provide the tempoary directory") {
      try expect((Path.temporary + "../../..").normalize()) == Path("/var/folders")
      try expect(Path.temporary.exists).to.beTrue()
    }
  }

  $0.describe("reading") {
    $0.it("can read NSData from a file") {
      let path = Path("/etc/manpaths")
      let contents: NSData? = try path.read()
      let string = NSString(data:contents!, encoding: NSUTF8StringEncoding)!

      try expect(string.hasPrefix("/usr/share/man")).to.beTrue()
    }

    $0.it("errors when you read from a non-existing file as NSData") {
      let path = Path("/tmp/pathkit-testing")

      try expect {
        try path.read() as NSData
      }.toThrow()
    }

    $0.it("can read a String from a file") {
      let path = Path("/etc/manpaths")
      let contents: String? = try path.read()

      try expect(contents?.hasPrefix("/usr/share/man")).to.beTrue()
    }

    $0.it("errors when you read from a non-existing file as a String") {
      let path = Path("/tmp/pathkit-testing")

      try expect {
        try path.read() as String
      }.toThrow()
    }
  }

  $0.describe("writing") {
    $0.it("can write NSData to a file") {
      let path = Path("/tmp/pathkit-testing")
      let data = "Hi".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

      try expect(path.exists).to.beFalse()

      try path.write(data!)
      try expect(try? path.read()) == "Hi"
      try path.delete()
    }

    $0.it("throws an error on failure writing NSData") {
      let path = Path("/")
      let data = "Hi".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

      try expect {
        try path.write(data!)
      }.toThrow()
    }

    $0.it("can write a String to a file") {
      let path = Path("/tmp/pathkit-testing")

      try path.write("Hi")
      try expect(try path.read()) == "Hi"
      try path.delete()
    }

    $0.it("thows an error on failure writing a String") {
      let path = Path("/")

      try expect {
        try path.write("hi")
      }.toThrow()
    }
  }

  $0.it("can return the parent directory of a path") {
    try expect((fixtures + "directory/child").parent()) == fixtures + "directory"
    try expect((fixtures + "symlinks/directory").parent()) == fixtures + "symlinks"
    try expect((fixtures + "directory/..").parent()) == fixtures + "directory/../.."
    try expect(Path("/").parent()) == "/"
  }

  $0.it("can return the children") {
    let children = try fixtures.children()
    try expect(children) == ["directory", "file", "permissions", "symlinks"].map { fixtures + $0 }
  }

  $0.it("can return the recursive children") {
    let parent = fixtures + "directory"
    let children = try parent.recursiveChildren()
    try expect(children) == ["child", "subdirectory", "subdirectory/child"].map { parent + $0 }
  }

  $0.it("conforms to SequenceType") {
    let path = fixtures + "directory"
    var children = ["child", "subdirectory"].map { path + $0 }
    let generator = path.generate()
    while let child = generator.next() {
      generator.skipDescendants()
      if let index = children.indexOf(child) {
        children.removeAtIndex(index)
      } else {
        throw failure(reason: "Generated unexpected element: <\(child)>")
      }
    }

    try expect(children.isEmpty).to.beTrue()
  }

  $0.it("can be pattern matched") {
    try expect(Path("/var") ~= "~").to.beFalse()
    try expect(Path("/Users") ~= "/Users").to.beTrue()
    try expect(Path("/Users") ~= "~/..").to.beTrue()
  }

  $0.it("can be compared") {
    try expect(Path("a")) < Path("b")
  }

  $0.it("can be appended to") {
    // Trivial cases.
    try expect(Path("a/b")) == "a" + "b"
    try expect(Path("a/b")) == "a/" + "b"

    // Appending (to) absolute paths
    try expect(Path("/")) == "/" + "/"
    try expect(Path("/")) == "/" + ".."
    try expect(Path("/a")) == "/" + "../a"
    try expect(Path("/b")) == "a" + "/b"

    // Appending (to) '.'
    try expect(Path("a")) == "a" + "."
    try expect(Path("a")) == "a" + "./."
    try expect(Path("a")) == "." + "a"
    try expect(Path("a")) == "./." + "a"
    try expect(Path(".")) == "." + "."
    try expect(Path(".")) == "./." + "./."

    // Appending (to) '..'
    try expect(Path(".")) == "a" + ".."
    try expect(Path("a")) == "a/b" + ".."
    try expect(Path("../..")) == ".." + ".."
    try expect(Path("b")) == "a" + "../b"
    try expect(Path("a/c")) == "a/b" + "../c"
    try expect(Path("a/b/d/e")) == "a/b/c" + "../d/e"
    try expect(Path("../../a")) == ".." + "../a"
  }

  $0.describe("glob") {
    $0.it("Path static glob") {
      let pattern = (fixtures + "permissions/*able").description
      let paths = Path.glob(pattern)

      let results = try (fixtures + "permissions").children().map { $0.absolute() }
      try expect(paths) == results
    }

    $0.it("can glob inside a directory") {
      let paths = fixtures.glob("permissions/*able")

      let results = try (fixtures + "permissions").children().map { $0.absolute() }
      try expect(paths) == results
    }
  }
}
