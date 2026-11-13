-- Plugin setup. Each block is independent: comment one out to disable that plugin.
-- Plugins come from package.toml (`ya pkg install`); this only configures them.

-- full-border: box around every pane. (starship.yazi's optional Tab.build override would
-- clash with this; that override is not used.)
require("full-border"):setup { set = "rounded" }

-- git: status signs in the file list. Fetchers are registered in yazi.toml.
require("git"):setup { order = 1500 }

-- starship: the same prompt as the shell in Yazi's header. Reads STARSHIP_CONFIG from the
-- environment, so it matches whatever config the shell uses. Without starship installed the
-- header is just empty.
require("starship"):setup()

-- smart-enter: `l` opens files and enters directories (bound in keymap.toml). Defaults are fine.
