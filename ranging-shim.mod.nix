{
  perSystem =
    {
      system,
      lib,
      pkgs,
      ...
    }@args:
    let
      inherit (lib.attrsets) getAttr;

      pkgs = import args.pkgs.path {
        inherit system;
        config = args.pkgs.config // {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };
    in
    {
      packages.ranging-shim = pkgs.stdenv.mkDerivation {
        pname = "ranging-shim";
        version = "1.0";

        dontUnpack = true;

        # aapt = standalone aapt2, apksigner bundles its own JRE, jdk for keytool.
        nativeBuildInputs = [
          pkgs.aapt
          pkgs.apksigner
          pkgs.jdk
        ];

        buildPhase = ''
          runHook preBuild

          export HOME="$NIX_BUILD_TOP"

          aapt2 link --manifest ${pkgs.writeText "AndroidManifest.xml" ''
            <?xml version="1.0" encoding="utf-8"?>
            <manifest xmlns:android="http://schemas.android.com/apk/res/android"
                package="hack.rangingshim"
                android:versionCode="1"
                android:versionName="1.0">

                <uses-sdk
                    android:minSdkVersion="24"
                    android:targetSdkVersion="35" />

                <permission
                    android:name="android.permission.RANGING"
                    android:permissionGroup="android.permission-group.NEARBY_DEVICES"
                    android:protectionLevel="dangerous" />

                <application
                    android:hasCode="false"
                    android:label="RANGING shim" />

            </manifest>
          ''} -I ${
            getAttr "androidsdk"
            <| pkgs.androidenv.composeAndroidPackages {
              platformVersions = [ "36" ];
              buildToolsVersions = [ ];
              includeEmulator = false;
              includeSystemImages = false;
              includeNDK = false;
            }
          }/libexec/android-sdk/platforms/android-36/android.jar -o unsigned.apk

          # Throwaway key.
          keytool -genkeypair -keystore ks.jks -storepass android -keypass android \
            -alias k -dname CN=ranging-shim -keyalg RSA -validity 10000

          apksigner sign --ks ks.jks --ks-pass pass:android \
            --out ranging-shim-release.apk unsigned.apk

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir --parents "$out"
          install --mode=644 --target-directory="$out" ranging-shim-release.apk
          runHook postInstall
        '';
      };
    };
}
