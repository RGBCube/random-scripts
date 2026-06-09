#!/usr/bin/env nu
# nativeBuildInputs = [ pkgs.git ];

def main [
  --org (-o): string = ""
  --user (-u): string = ""
] {
  let path = if not ($org | is-empty) {
    "orgs/" + $org
  } else if not ($user | is-empty) {
    "users/" + $user
  } else {
    print --stderr $"(ansi red)error:(ansi reset) either org or user must be supplied"
    exit 1
  }

  http get https://api.github.com/($path)/repos
  | par-each { git clone $"https://github.com/($in.full_name)" }

  print --stderr "\nDone!"
}
