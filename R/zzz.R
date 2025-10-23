.onAttach <- function(libname, pkgname) {
  packageStartupMessage(cli::format_inline(
    "{.pkg azr} {utils::packageVersion('azr')} | Azure OAuth 2.0 credential chain"
  ))

  packageStartupMessage(cli::format_bullets_raw(c(i = "Environment configuration:")))
  for (bullet in cli::format_bullets_raw(get_env_config())) {
    packageStartupMessage(bullet)
  }
}
