#!/usr/bin/env nu

let root = input "enter linearized directory path: "
mkdir $root

if (ls $root | is-not-empty) {
  print $"(ansi red)directory not empty, delete it and try again(ansi reset)"
  exit 1
}

let source = input "enter directory to linearize: "

let linked = ls ...(glob --no-dir $"($source)/**/*")
| where type == file
| group-by size | values
| par-each {|group|
  if ($group | length) == 1 {
    return $group
  }

  let by_identity = $group
  | par-each { insert hash (open $in.name | hash sha256) }
  | group-by hash | values

  $by_identity
  | where { ($in | length) > 1 }
  | each {|entries|
    let separator = $"(ansi reset)\n- (ansi red)"
    print $"found identical files: \n- (ansi red)($entries | get name | str join $separator)(ansi reset)"
  }

  $by_identity
  | each { get 0 }
}
| flatten
| par-each {|entry|
  let parse = $entry.name | path parse

  let date = $entry.modified | format date "%Y-%m-%dT%H:%M:%S"
  let name = $"($date)-($entry.hash? | default "unique" | str substring ..6)-($parse.stem).($parse.extension)"

  print $"creating (ansi green)($name)(ansi reset)"
  ln $entry.name ($root | path join $name)
}
| length

print $"linked a total of (ansi cyan)($linked)(ansi reset) files"
