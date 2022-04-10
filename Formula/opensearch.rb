  url "https://github.com/opensearch-project/OpenSearch/archive/1.3.1.tar.gz"
  sha256 "1a368a9057eede7a0c20792cbae72a7b1bbcbbbee7ebb3fc3c6bb7782a7bd345"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "82c9268efa73564391f6b99ea0c37d7d48c3a61f3652c275f499c31c57a11e2c"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "82c9268efa73564391f6b99ea0c37d7d48c3a61f3652c275f499c31c57a11e2c"
    sha256 cellar: :any_skip_relocation, monterey:       "cf84778e6ec1b476640697735bcad761f0594b6c3b4a931c2841440b19aa31d0"
    sha256 cellar: :any_skip_relocation, big_sur:        "cf84778e6ec1b476640697735bcad761f0594b6c3b4a931c2841440b19aa31d0"
    sha256 cellar: :any_skip_relocation, catalina:       "cf84778e6ec1b476640697735bcad761f0594b6c3b4a931c2841440b19aa31d0"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "ac5d9a44a6f2577800a443da819f9de9d5c0e9d71c45c149102cc61876e2e82e"
  # Backport of https://github.com/opensearch-project/OpenSearch/pull/1668
  # TODO: Remove when available in release
  patch :DATA if Hardware::CPU.arm?

    platform = OS.kernel_name.downcase
    platform += "-arm64" if Hardware::CPU.arm?
    system "gradle", "-Dbuild.snapshot=false", ":distribution:archives:no-jdk-#{platform}-tar:assemble"
        Dir["../distribution/archives/no-jdk-#{platform}-tar/build/distributions/opensearch-*.tar.gz"].first
                             "-Epath.data=#{testpath}/data",
                             "-Epath.logs=#{testpath}/logs"
    sleep 60

__END__
diff --git a/distribution/archives/build.gradle b/distribution/archives/build.gradle
index 2c5b91f7e135d0e4a38cf3588bc12a7f28601d39..ac70ee04444c7672981cd31b84b852bdeb17476a 100644
--- a/distribution/archives/build.gradle
+++ b/distribution/archives/build.gradle
@@ -95,6 +95,13 @@ distribution_archives {
     }
   }

+  darwinArm64Tar {
+    archiveClassifier = 'darwin-arm64'
+    content {
+      archiveFiles(modulesFiles('darwin-arm64'), 'tar', 'darwin', 'arm64', true)
+    }
+  }
+
   noJdkDarwinTar {
     archiveClassifier = 'no-jdk-darwin-x64'
     content {
@@ -102,6 +109,13 @@ distribution_archives {
     }
   }

+  noJdkDarwinArm64Tar {
+    archiveClassifier = 'no-jdk-darwin-arm64'
+    content {
+      archiveFiles(modulesFiles('darwin-arm64'), 'tar', 'darwin', 'arm64', false)
+    }
+  }
+
   freebsdTar {
     archiveClassifier = 'freebsd-x64'
     content {
diff --git a/distribution/archives/darwin-arm64-tar/build.gradle b/distribution/archives/darwin-arm64-tar/build.gradle
new file mode 100644
index 0000000000000000000000000000000000000000..bb3e3a302c8d6a96a319a1474e964757f5ed3f57
--- /dev/null
+++ b/distribution/archives/darwin-arm64-tar/build.gradle
@@ -0,0 +1,13 @@
+/*
+ * SPDX-License-Identifier: Apache-2.0
+ *
+ * The OpenSearch Contributors require contributions made to
+ * this file be licensed under the Apache-2.0 license or a
+ * compatible open source license.
+ *
+ * Modifications Copyright OpenSearch Contributors. See
+ * GitHub history for details.
+ */
+
+// This file is intentionally blank. All configuration of the
+// distribution is done in the parent project.
diff --git a/distribution/archives/no-jdk-darwin-arm64-tar/build.gradle b/distribution/archives/no-jdk-darwin-arm64-tar/build.gradle
new file mode 100644
index 0000000000000000000000000000000000000000..bb3e3a302c8d6a96a319a1474e964757f5ed3f57
--- /dev/null
+++ b/distribution/archives/no-jdk-darwin-arm64-tar/build.gradle
@@ -0,0 +1,13 @@
+/*
+ * SPDX-License-Identifier: Apache-2.0
+ *
+ * The OpenSearch Contributors require contributions made to
+ * this file be licensed under the Apache-2.0 license or a
+ * compatible open source license.
+ *
+ * Modifications Copyright OpenSearch Contributors. See
+ * GitHub history for details.
+ */
+
+// This file is intentionally blank. All configuration of the
+// distribution is done in the parent project.
diff --git a/distribution/build.gradle b/distribution/build.gradle
index 33232195973f0960f3008f42c6dde84ff410779e..356aaa269e10662872b175a1fcbb5ef30aebc96b 100644
--- a/distribution/build.gradle
+++ b/distribution/build.gradle
@@ -280,7 +280,7 @@ configure(subprojects.findAll { ['archives', 'packages'].contains(it.name) }) {
   // Setup all required JDKs
   project.jdks {
     ['darwin', 'linux', 'windows'].each { platform ->
-      (platform == 'linux' ? ['x64', 'aarch64'] : ['x64']).each { architecture ->
+      (platform == 'linux' || platform == 'darwin' ? ['x64', 'aarch64'] : ['x64']).each { architecture ->
         "bundled_${platform}_${architecture}" {
           it.platform = platform
           it.version = VersionProperties.getBundledJdk(platform)
@@ -353,7 +353,7 @@ configure(subprojects.findAll { ['archives', 'packages'].contains(it.name) }) {
           }
         }
         def buildModules = buildModulesTaskProvider
-        List excludePlatforms = ['darwin-x64', 'freebsd-x64', 'linux-x64', 'linux-arm64', 'windows-x64']
+        List excludePlatforms = ['darwin-x64', 'freebsd-x64', 'linux-x64', 'linux-arm64', 'windows-x64', 'darwin-arm64']
         if (platform != null) {
           excludePlatforms.remove(excludePlatforms.indexOf(platform))
         } else {
diff --git a/settings.gradle b/settings.gradle
index 3fdc7ec03bf997b7b4ca11992aaa9d5c619376b9..bcf1fd5937668d8856496584b7f22cfbc831c724 100644
--- a/settings.gradle
+++ b/settings.gradle
@@ -34,6 +34,8 @@ List projects = [
   'distribution:archives:windows-zip',
   'distribution:archives:no-jdk-windows-zip',
   'distribution:archives:darwin-tar',
+  'distribution:archives:darwin-arm64-tar',
+  'distribution:archives:no-jdk-darwin-arm64-tar',
   'distribution:archives:no-jdk-darwin-tar',
   'distribution:archives:freebsd-tar',
   'distribution:archives:no-jdk-freebsd-tar',