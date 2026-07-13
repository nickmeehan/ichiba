#!/usr/bin/env ruby
load File.expand_path('../bin/dot2mermaid', __dir__)

def assert_includes(out, want)
  abort "MISSING: #{want}\n---got---\n#{out}" unless out.include?(want)
end

out = convert(<<~'DOT')
  digraph FixLoop {
      graph [goal="Make tests pass", model_stylesheet="styles.css"]
      rankdir=LR
      start [shape=Mdiamond]
      exit  [shape=Msquare]
      // agent prompt contains ], quotes, and comment markers — must not break parsing
      implement [shape=box,
                 prompt="Respond with {\"done\": [true]} // no comment"]
      test [shape=parallelogram, script="bun test", language=shell]
      review [shape=hexagon, label="Ship it?"]

      start -> implement -> test
      test -> implement [condition="outcome=failed", label="fix"]
      test -> review    [condition="outcome=succeeded"]
      review -> exit      [label="[S] Ship"]
      review -> implement [label="[R] Revise"]
  }
DOT

assert_includes out, 'flowchart LR'
assert_includes out, 'start(["start"])'
assert_includes out, 'exit(["exit"])'
assert_includes out, 'implement["implement"]'
assert_includes out, 'test[/"test"/]'
assert_includes out, 'review{{"Ship it?"}}'
assert_includes out, 'start --> implement'
assert_includes out, 'implement --> test'
assert_includes out, 'test -->|"fix"| implement'
assert_includes out, 'test -->|"outcome=succeeded"| review'
assert_includes out, 'review -->|"[S] Ship"| exit'

# "end" is reserved in Mermaid flowcharts; ids must be sanitized
out = convert('digraph X { a -> end }')
assert_includes out, 'a --> end_'

# default direction is TD when rankdir is absent
assert_includes convert('digraph X { a -> b }'), 'flowchart TD'

puts 'ok'
