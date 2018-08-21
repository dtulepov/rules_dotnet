load(
    "@io_bazel_rules_dotnet//dotnet/private:context.bzl",
    "dotnet_context",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:common.bzl",
    "paths", "dicts"
)


def _dotnet_nuget_impl(ctx,                         
        build_file = None,
        build_file_content = None):
  """dotnet_nuget_impl emits actions for exposing nunit assmebly."""

  package = ctx.attr.package
  output_dir = ctx.path("")
  if ctx.attr.use_nuget_client and ctx.os.name.startswith('windows'):
    """use_nuget_client for private nuget feed (tfs/vsts/etc)"""
    nuget = ctx.path(ctx.attr._nuget_exe)
    nuget_cmd = [nuget, "install", "-Version", ctx.attr.version,
                    "-OutputDirectory", output_dir,
                    "-Source", ctx.attr.source, ctx.attr.package]
    result = ctx.execute(nuget_cmd)
    if result.return_code:
        fail("Nuget command failed: %s (%s)" % (result.stderr, " ".join(nuget_cmd)))
  else:
    url = ctx.attr.source + "/" + ctx.attr.package + "/" + ctx.attr.version
    ctx.download_and_extract(url, output_dir, ctx.attr.sha256, type="zip")  

  build_file_name = "BUILD" if not ctx.path("BUILD").exists else "BUILD.bazel"

  if build_file_content:
    ctx.file(build_file_name, build_file_content)
  elif build_file:
    ctx.symlink(ctx.path(build_file), build_file_name)
  else:
    ctx.template(build_file_name,
        Label("@io_bazel_rules_dotnet//dotnet/private:BUILD.nuget.bazel"),
        executable = False,
    )

_dotnet_nuget_attrs = {
    "_nuget_exe": attr.label(default=Label("@nuget//file:nuget.exe")),
    # Sources to download the nuget packages from
    "source": attr.string(default = "https://www.nuget.org/api/v2/package"),
    # The name of the nuget package
    "package": attr.string(mandatory=True),
    # The version of the nuget package
    "version": attr.string(mandatory=True),
    "sha256": attr.string(mandatory=True),
    "use_nuget_client": attr.bool(default=False)
}

dotnet_nuget = repository_rule(
    _dotnet_nuget_impl,
    attrs = _dotnet_nuget_attrs,
)

def _dotnet_nuget_new_impl(repository_ctx):
  build_file = repository_ctx.attr.build_file
  build_file_content = repository_ctx.attr.build_file_content
  if not (build_file_content or build_file):
    fail("build_file or build_file_content is required")
  _dotnet_nuget_impl(repository_ctx, build_file, build_file_content)

dotnet_nuget_new = repository_rule(
    _dotnet_nuget_new_impl,
    attrs = dicts.add(_dotnet_nuget_attrs, {
        "build_file": attr.label(allow_files = True),
        "build_file_content": attr.string(),
    }),
)