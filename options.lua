
local ItemCache = AuctionFaster:GetModule('ItemCache');
--local Tooltip = AuctionFaster:GetModule('ItemCache');


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
				AuctionFaster.db.global.enabled = val;
			end,
			get = function(info) return AuctionFaster.db.global.enabled end
		},
		fastMode = {
			name = 'Fast Mode',
			desc = 'In fast mode auction seller may not be correctly updated but speed of searching is greatly increased',
			type = 'toggle',
			width = 'full',
			set = function(info, val)
				AuctionFaster.db.global.fastMode = val;
			end,
			get = function(info) return AuctionFaster.db.global.fastMode end
		},
		enableToolTips = {
			name = 'Enable Tooltip information',
			desc = 'You will see bid / buy prices on item tooltips',
			type = 'toggle',
			width = 'full',
			set = function(info, val)
				AuctionFaster.db.global.tooltipsEnabled = val;
				if val then
					AuctionFaster:EnableModule('Tooltip');
				else
					AuctionFaster:DisableModule('Tooltip');
				end
			end,
			get = function(info) return AuctionFaster.db.global.tooltipsEnabled end
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
		wipe = {
			name = 'Wipe AuctionFaster item cache and settings',
			desc = 'Wipe AuctionFaster item cache and settings',
			type = 'execute',
			--width = 'full',
			func = function(info, val)
				ItemCache:WipeItemCache();
				print('Settins wiped!');
			end,
		},
	},
}

AuctionFaster.defaults = {
	global = {
		enabled = true,
		auctionDuration = 2,
		fastMode = true
	}
};

function AuctionFaster:IsFastMode()
	return self.db.global.fastMode;
end