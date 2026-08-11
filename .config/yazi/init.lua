require("yatline"):setup()
require("recycle-bin"):setup()

require("git"):setup {
	-- Order of status signs showing in the linemode
	order = 1500,
}
