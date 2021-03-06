load(
    "@io_bazel_rules_dotnet//dotnet/private:context.bzl",
    "dotnet_context",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
    "DotnetResource",
)


def _core_library_impl(ctx):
  """core_library_impl emits actions for compiling dotnet executable assembly."""
  dotnet = dotnet_context(ctx)
  name = ctx.label.name
 
  library = dotnet.library(dotnet,
      name = name,
      srcs = ctx.attr.srcs,
      deps = ctx.attr.deps,
      resources = ctx.attr.resources,
      out = ctx.attr.out,
      defines = ctx.attr.defines,
      unsafe = ctx.attr.unsafe,
  )

  transitive_files = [d.result for d in library.transitive.to_list()]

  if library.pdb:
    pdbs = [library.pdb]
  else:
    pdbs = []

  runfiles = ctx.runfiles(files = [dotnet.stdlib, library.result] + pdbs, transitive_files=depset(direct=transitive_files))
  if library.runfiles:
    runfiles.merge(library.runfiles)

  return [
      library,
      DefaultInfo(
          files = depset([library.result]),
          runfiles = runfiles,
      ),
  ]
  
core_library = rule(
    _core_library_impl,
    attrs = {
        "deps": attr.label_list(providers=[DotnetLibrary]),
        "resources": attr.label_list(providers=[DotnetResource]),
        "srcs": attr.label_list(allow_files = FileType([".cs"])),        
        "out": attr.string(),
        "defines": attr.string_list(),
        "unsafe": attr.bool(default = False),
        "_dotnet_context_data": attr.label(default = Label("@io_bazel_rules_dotnet//:core_context_data"))
    },
    toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain_core"],
    executable = False,
)