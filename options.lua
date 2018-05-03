AuctionFaster.options = {
	type = 'group',
	name = 'AuctionFaster Options',
	inline = false,
	args = {
		enable = {
			name = 'Enable AuctionFaster',
			desc = 'Enable AuctionFaster',
			type = 'toggle',
			width = 'full',
			set = function(info, val)
				AuctionFaster.db.global.enabled = not val;
			end,
			get = function(info) return not AuctionFaster.db.global.enabled end
		},
		wipe = {
			name = 'Wipe AuctionFaster item cache and settings',
			desc = 'Wipe AuctionFaster item cache and settings',
			type = 'execute',
			--width = 'full',
			func = function(info, val)
				AuctionFaster:WipeItemCache();
				print('Settins wiped!');
			end,
		},
		auctionDuration = {
			name = 'Auction Duration',
			type = 'select',
			values = {
				[1] = '12 Hours',
				[2] = '24 Hours',
				[3] = '48 Hours',
			},
			set = function(info, val)
				AuctionFaster.db.global.auctionDuration = val;
			end,
			get = function(info) return AuctionFaster.db.global.auctionDuration end
		},
	},
}

AuctionFaster.defaults = {
	global = {
		enabled = true,
		auctionDuration = 2;
	}
};