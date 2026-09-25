# Builder functions for AI agent MCP servers.
# Imported by default.nix and exposed via _module.args.aiLib.
{ lib, pkgs }:
{
  # Build a local (stdio) MCP server definition.
  mkLocalMcp =
    {
      command,
      package ? null,
      environment ? { },
      enabled ? true,
    }:
    {
      type = "local";
      inherit
        command
        environment
        enabled
        package
        ;
      url = null;
      headers = { };
    };

  # Build a remote (SSE/streamable-HTTP) MCP server definition.
  mkRemoteMcp =
    {
      url,
      headers ? { },
      enabled ? true,
    }:
    {
      type = "remote";
      inherit url headers enabled;
      command = [ ];
      environment = { };
      package = null;
    };
}
