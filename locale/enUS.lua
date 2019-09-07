local L = LibStub('AceLocale-3.0'):NewLocale('AuctionFaster', 'enUS', true);

L['AuctionFaster - Historical Options'] = true;
L['Enable Historical Data Collection'] = true;
L['Days to keep data (5-50)'] = true;
L['AuctionFaster - Pricing Options'] = true;
L['Historical Options'] = true;
L['Pricing Options'] = true;
L['Maximum difference bid to buy (1-100%)'] = true;
L['AuctionFaster Options'] = true;
L['AuctionFaster'] = true;
L['Enable AuctionFaster'] = true;
L['Fast Mode'] = true;
L['Enable ToolTips'] = true;
L['12 Hours'] = true;
L['24 Hours'] = true;
L['48 Hours'] = true;
L['Do not set'] = true;
L['Sell Tab'] = true;
L['Buy Tab'] = true;
L['Wipe Item Cache'] = true;
L['Reset Tutorials'] = true;
L['Auction Duration'] = true;
L['Set Default Tab'] = true;
L['Item cache wiped!'] = true;
L['Tutorials reset!'] = true;
L['Top'] = true;
L['Top Right'] = true;
L['Right'] = true;
L['Bottom Right'] = true;
L['Bottom'] = true;
L['Bottom Left'] = true;
L['Left'] = true;
L['Top Left'] = true;
L['Sell Tab Settings'] = true;
L['Enable ToolTips for Items'] = true;
L['Tooltip Anchor'] = true;
L['Item Tooltip Anchor'] = true;
L['Buy Tab Settings'] = true;
L['Query failed, retrying: %d'] = true;
L['Cannot query AH. Please wait a bit longer or reload UI'] = true;
L['Could not pick up item from inventory'] = true;
L['Posting: %s for:\nper auction: %s\nper item: %s\n# stacks: %d stack size: %d'] = true;

-- chain buy
L['Chain Buy'] = true;
L['Qty: %d'] = true;
L['Per Item: %s'] = true;
L['Total: %s'] = true;
L['Bought so far: %d'] = true;
L['Queue'] = true;
L['Fast Mode - AuctionFaster will NOT wait until you actually buy an item.\n\n'..
	'This may result in inaccurate amount of bought items and some missed auctions.\n' ..
	'|cFFFF0000Use this only if you don\'t care about how much you will buy and want to buy fast.|r'] = true;

-- item cache
L['Invalid cache key'] = true;

-- pricing
L['LowestPrice'] = true;
L['WeightedAverage'] = true;
L['StackAware'] = true;
L['StandardDeviation'] = true;
L['No auctions found'] = true;
L['No auction found with minimum quantity: %d'] = true;
L['Tooltips enabled'] = true;
L['Tooltips disabled'] = true;
L['Lowest Bid: '] = true;
L['Lowest Buy: '] = true;
L['Filters'] = true;
L['Exact Match'] = true;
L['Level from'] = true;
L['Level to'] = true;
L['Sub Category'] = true;
L['Category'] = true;
L['No query was searched before'] = true;
L['Search in progress...'] = true;
L['Nothing was found for this query.'] = true;
L['Pages: %d'] = true;
L['Queue Qty: %d'] = true;
L['Please select item first'] = true;
L['No auctions found with requested stack count: %d'] = true;
L['Enter query and hit search button first'] = true;
L['No auction found for minimum stacks: %d'] = true;
L['Addon Tutorial'] = true;
L['Addon settings'] = true;

-- buy tutorials
L['Welcome to AuctionFaster.\n\nI recommend checking out\ntutorial at least once\nbefore you ' ..
	'accidentially\nbuy half of the auction house.\n\n:)'] = true;
L['Once you enter search query\nthis button will add it to\nthe favorites.'] = true;
L['This button opens up filters.\nClick again to close.'] = true;
L['Search results.\n\nThere are 3 major shortcuts:\n\n'] = true;
L['Shift + Click - Instant buy\n'] = true;
L['Alt + Click - Add to queue\n'] = true;
L['Ctrl + Click - Chain buy\n'] = true;
L['Your favorites\nClicking on the name will\ninstanty search for this query.\n\n'] = true;
L['Click delete button to remove.'] = true;
L['Chain buy will add all auctions\nfrom the first one you select\nto the bottom '] = true;
L['of the list\nto the Buy Queue.\n\n'] = true;
L['You will still need to confirm them.'] = true;
L['Status of the current buy queue\n\nQty will show you actual quantity\n'] = true;
L['and progress bar will show\nthe amount of auctions.'] = true;
L['Minimal amount of quantity\nyou are interested in.\n\n'] = true;
L['This is used by two buttons on the left.'] = true;
L['Adds all auctions to the queue that has at least the amount of quantity entered'] = true;
L[' in the box on the right'] = true;
L['Finds the first auction '] = true;
L['across all the pages'] = true;
L[' that meets the minimum quantity\n\n'] = true;
L['You need to enter a search query first'] = true;
L['Opens this tutorial again.\nHope you liked it\n\n:)\n\n'] = true;

-- buy UI
L['Buy Items'] = true;
L['AuctionFaster - Buy'] = true;
L['Search'] = true;

L['Buy'] = true;
L['Skip'] = true;
L['Close'] = true;

-- sniper
L['Sniper'] = true;
L['Auto Refresh'] = true;
L['Refresh Interval'] = true;
L['More features\ncoming soon'] = true;

-- buy ui
L['Add to Queue'] = true;
L['Add With Min Stacks'] = true;
L['Find X Stacks'] = true;
L['Min Stacks'] = true;
L['Please select auction first'] = true;
L['Enter a correct stack amount 1-200'] = true;
L['Queue Qty: %d'] = true;
L['Auctions: %d / %d'] = true;
L['Favorite Searches'] = true;
L['Name'] = true;
L['Seller'] = true;
L['Qty'] = true;
L['Bid / Item'] = true;
L['Buy / Item'] = true;
L['Chose your search criteria nad press "Search"'] = true;

-- sell functions
L['Qty: %d, Max Stacks: %d, Remaining: %d'] = true;
L['Last scan: %s'] = true;
L['Stack Size (Max: %d)'] = true;
L['Please refresh auctions first'] = true;
L['Yes'] = true;
L['No'] = true;
L['Incomplete sell'] = true;
L['You still have %d of %s Do you wish to sell rest?'] = true;

-- sell info pane
L['Auction Info'] = true;
L['Deposit: %s'] = true;
L['# Auctions: %d'] = true;
L['Duration: %s'] = true;
L['Historical Data'] = true;
L['Per auction: %s'] = true;
L['No historical data available for: %s'] = true;
L['Lowest Buy'] = true;
L['Trend Lowest Buy'] = true;
L['Average Buy'] = true;
L['Trend Average Buy'] = true;
L['Highest Buy'] = true;
L['Test Line'] = true;
L['Historical Data: '] = true;

-- sell item settings
L['Item Settings'] = true;
L['No Item selected'] = true;
L['Remember Stack Settings'] = true;
L['Remember Last Price'] = true;
L['Always Undercut'] = true;
L['Use Custom Duration'] = true;
L['12h'] = true;
L['24h'] = true;
L['48h'] = true;
L['days ago'] = true;
L['hours ago'] = true;
L['minutes ago'] = true;
L['Pricing Model'] = true;
L['If there is no auctions of this item,'] = true;
L['remember last price.'] = true;
L['Your price will be overriden'] = true;
L['if "Always Undercut" options is checked!'] = true;
L['Checking this option will make\nAuctionFaster remember how much\n' ..
	'stacks you wish to sell at once\nand how big is stack'] = true;
L['By default, AuctionFaster always undercuts price,\neven if you toggle "Remember Last Price"\n'..
	'If you uncheck this option AuctionFaster\nwill never undercut items for you'] = true;

-- sell tutorial
L['Welcome to AuctionFaster.\n\nI recommend checking out sell tutorial at least once before you accidentally sell your precious goods.\n\n:)'] = true;
L['Here is the list of all inventory items you can sell, no need to drag anything.\n\n'] = true;
L['After you select item, AuctionFaster will automatically make a scan of first page and undercut set bid/buy according to price model selected.'] = true;
L['Here you will see selected item. Max stacks means how much of stacks can you sell according to your setting. Remaining means how much quantity will still stay in bag after selling item.'] = true;
L['AuctionFaster keeps auctions cache for about 10 minutes, you can see when last real scan was performed.\n\n'] = true;
L['You can click Refresh Auctions to scan again'] = true;
L['Your bid price '] = true;
L['per one item.'] = true;
L['AuctionFaster understands a lot of money formats'] = true;
L[', for example:\n\n' .. '5g 6s 19c\n5g6s86c\n999s 50c\n3000s\n9000000c'] = true;
L['Your buyout price '] = true;
L[' Same money formats as bid per item.'] = true;
L['Maximum number of stacks you wish to sell.\n\n'] = true;
L['Set this to 0 to sell everything'] = true;
L['This opens up item settings.\nClick again to close.\n\n'] = true;
L['Hover over checkboxes to see what the options are.\n\n'] = true;
L['Those settings are per specific item'] = true;
L['This opens auction informations:\n\n' ..
	'- Total auction buy price.\n' ..
	'- Deposit cost.\n' ..
	'- Number of auctions\n' ..
	'- Auction duration\n\n'] = true;	
L['This will change dynamically when you change stack size or max stacks.'] = true;
L['Here is a list of auctions of currently selected item.\n'] = true;
L['You can be sure your item will be cheapest.\n'] = true;
L['These are always sorted by lowest price per item.'] = true;
L['This button allows you to buy selected item. Useful for restocking.'] = true;
L['Posts %s of selected item regardless of your\n"# Stacks" settings'] = true;
L['Posts %s of selected item according to your\n"# Stacks" settings'] = true;
L['one auction'] = true;
L['all auctions'] = true;
L['Once you close this tutorial it won\'t show again unless you click it'] = true;

-- sell ui
L['Sell Items'] = true;
L['AuctionFaster - Sell'] = true;
L['Refresh inventory'] = true;
L['Sort settings'] = true;
L['Sort by'] = true;
L['Name'] = true;
L['Price'] = true;
L['Quality'] = true;
L['Direction'] = true;
L['Ascending'] = true;
L['Descending'] = true;
L['Filter items'] = true;
L['Bid Per Item'] = true;
L['Buy Per Item'] = true;
L['Stack Size'] = true;
L['# Stacks'] = true;
L['Refresh Auctions'] = true;
L['Post All'] = true;
L['Post One'] = true;
L['Lvl'] = true;