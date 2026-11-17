def main [command: string] {
  nu -c $"source devenv.nu; ($command)"
  exit $env.LAST_EXIT_CODE
}
