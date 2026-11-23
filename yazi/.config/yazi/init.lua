-- Plugin setup. Each block is independent: comment one out to disable that plugin.
-- Plugins come from package.toml (`ya pkg install`); this only configures them.

-- A bare require of a missing plugin stops Yazi from starting at all, as on a box
-- where `ya pkg install` hasn't run yet (or can't, offline). Guarded, a missing
-- plugin only loses its own feature.
local function setup(name, opts)
	local ok, plugin = pcall(require, name)
	if ok then
		plugin:setup(opts)
	end
end

-- full-border: box around every pane. (starship.yazi's optional Tab.build override would
-- clash with this; that override is not used.)
setup("full-border", { set = "rounded" })

-- git: status signs in the file list. Fetchers are registered in yazi.toml.
setup("git", { order = 1500 })

-- starship: the same prompt as the shell in Yazi's header. Reads STARSHIP_CONFIG from the
-- environment, so it matches whatever config the shell uses. Without starship installed the
-- header is just empty.
setup("starship")

-- smart-enter: `l` opens files and enters directories (bound in keymap.toml). Defaults are fine.
