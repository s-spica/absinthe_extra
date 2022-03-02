# Used by "mix format"
[
  import_deps: [:absinthe, :phoenix],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 80,
  locals_without_parens: [policy: 1, policy: 2],
  export: [locals_without_parens: [policy: 1, policy: 2]]
]
