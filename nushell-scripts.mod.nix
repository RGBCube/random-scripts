{
  perSystem =
    { lib, pkgs, ... }:
    let
      inherit (lib)
        readFile
        ;
      inherit (lib.attrsets)
        filterAttrs
        genAttrs
        getAttrFromPath
        mapAttrsToList
        ;
      inherit (lib.filesystem) readDir;
      inherit (lib.lists)
        concatMap
        filter
        head
        isList
        ;
      inherit (lib.strings)
        hasSuffix
        makeBinPath
        removeSuffix
        split
        splitString
        ;
      inherit (lib.trivial) flip;
    in
    {
      packages =
        readDir ./.
        |> filterAttrs (fileName: type: type == "regular" && hasSuffix ".nu" fileName)
        |> mapAttrsToList (fileName: _type: removeSuffix ".nu" fileName)
        |> flip genAttrs (
          pname:
          pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
            inherit pname;
            name = finalAttrs.pname;

            src = ./${pname}.nu;
            dontUnpack = true;

            dependencies =
              readFile finalAttrs.src
              |> split "#[[:space:]]*nativeBuildInputs[[:space:]]*=[[:space:]]*[[]([^]]*)[]][[:space:]]*;"
              |> filter isList
              |> concatMap (matches: matches |> head |> split "pkgs[.]([A-Za-z0-9_+.-]+)" |> filter isList)
              |> map (matches: matches |> head |> splitString "." |> flip getAttrFromPath pkgs);

            nativeBuildInputs = [
              pkgs.makeWrapper
              pkgs.nushell
            ]
            ++ finalAttrs.dependencies;

            installPhase = ''
              runHook preInstall

              install -Dm755 "$src" "$out/bin/${finalAttrs.pname}"
              patchShebangs "$out/bin/${finalAttrs.pname}"
              wrapProgram "$out/bin/${finalAttrs.pname}" \
                --prefix PATH : ${makeBinPath finalAttrs.dependencies}

              runHook postInstall
            '';
          })
        );
    };
}
