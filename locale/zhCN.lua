local L = LibStub('AceLocale-3.0'):NewLocale('AuctionFaster', 'zhCN');
if not L then return end

L['AuctionFaster - Historical Options'] = 'AuctionFaster - 历史选项'
L['Enable Historical Data Collection'] = '启用历史纪录'
L['Days to keep data (5-50)'] = '纪录的天数，5至50天'
L['AuctionFaster - Pricing Options'] = 'AuctionFaster - 价格选项'
L['Historical Options'] = '历史选项'
L['Pricing Options'] = '价格选项'
L['Maximum difference bid to buy (1-100%)'] = true;
L['AuctionFaster Options'] = 'AuctionFaster - 选项'
L['AuctionFaster'] = true;
L['Enable AuctionFaster'] = '启用AuctionFaster'
L['Fast Mode'] = '快速模式'
L['Enable ToolTips'] = '启用鼠标提示'
L['12 Hours'] = '12小时'
L['24 Hours'] = '24小时'
L['48 Hours'] = '48小时'
L['Do not set'] = '不设置'
L['Sell Tab'] = '出售分页'
L['Buy Tab'] = '购买分页'
L['Wipe Item Cache'] = '清除物品缓存'
L['Reset Tutorials'] = '重置新手教程'
L['Auction Duration'] = '拍卖时间'
L['Set Default Tab'] = '预设开启分页'
L['Item cache wiped!'] = '物品缓存已清除！'
L['Tutorials reset!'] = '新手教程已重置！'
L['Top'] = '上方'
L['Top Right'] = '右上'
L['Right'] = '右方'
L['Bottom Right'] = '右下'
L['Bottom'] = '下方'
L['Bottom Left'] = '左下'
L['Left'] = '左方'
L['Top Left'] = '左上'
L['Sell Tab Settings'] = '出售分页设置'
L['Enable ToolTips for Items'] = '启用物品的鼠标提示'
L['Tooltip Anchor'] = '鼠标提示锚点'
L['Item Tooltip Anchor'] = '物品提示锚点'
L['Buy Tab Settings'] = '购买分页设置'
L['Query failed, retrying: %d'] = '查询失败，重试%d次'
L['Cannot query AH. Please wait a bit longer or reload UI'] = '无法扫瞄拍卖行。请等一下或重载界面'
L['Could not pick up item from inventory'] = '无法从背包中选定物品'
L['Posting: %s for:\nper auction: %s\nper item: %s\n# stacks: %d stack size: %d'] = '上架%1$s：\n每组售价：%2$s\n单价：%3$s\n每组堆叠%5$d个，共出售%4$d组。'

-- chain buy
L['Chain Buy'] = '批量购买'
L['Qty: %d'] = '数量：%d'
L['Per Item: %s'] = '单价：%s'
L['Total: %s'] = '总价：%s'
L['Bought so far: %d'] = '已购买%d个'
L['Queue'] = true;
L['Fast Mode - Auction Faster will NOT wait until you actually buy an item.\n\n'..
	'This may result in inaccurate amount of bought items and some missed auctions.\n' ..
	'|cFFFF0000Use this only if you don\'t care about how much you will buy and want to buy fast.|r'] = '快速模式\n启用后，Auction Faster不会等到你“确定买到了”才显示下一项，按下购买按钮就直接显示下一项。\n'..'这可能或错过某些商品。\n\n'..'|cFFFF0000只在你不在乎买价和数量，只想快速扫货时使用。|r'

-- item cache
L['Invalid cache key'] = '无效关键字'

-- pricing
L['LowestPrice'] = '最低价格'
L['WeightedAverage'] = '平均价格'
L['StackAware'] = '忽略散装'
L['StandardDeviation'] = '标准偏差'
L['No auctions found'] = '没有找到拍卖品'
L['No auction found with minimum quantity: '] = '未找到符合最小堆叠数量为%d的拍卖品'
L['Tooltips enabled'] = '启用鼠标提示'
L['Tooltips disabled'] = '停用鼠标提示'
L['Lowest Bid: '] = '最低竞标价'
L['Lowest Buy: '] = '最低购买价'
L['Filters'] = '过滤条件'
L['Exact Match'] = '精确符合'
L['Level from'] = '等级自'
L['Level to'] = '等级至'
L['Sub Category'] = '子类别'
L['Category'] = '类别'
L['No query was searched before'] = '尚未开始检索'
L['Search in progress...'] = '正在搜索...'
L['Nothing was found for this query.'] = '这个关键字没有找到任何东西'
L['Pages: %d'] = '第%d页'
L['Queue Qty: %d'] = '队列中：%d'
L['Please select item first'] = '请先选定物品'
L['No auctions found with requested stack count: '] = '找不到符合最小堆叠数量的拍卖品'
L['Enter query and hit search button first'] = '先输入要搜索的物品关键字，然后点击搜索按钮'
L['No auction found for minimum stacks: '] = '该物品找不到符合过滤条件为最小堆叠%d的项目。'
L['Addon Tutorial'] = '新手教程'
L['Addon settings'] = '设置选项'

-- buy tutorials
L['Welcome to AuctionFaster.\n\nI recommend checking out\ntutorial at least once\nbefore you ' ..
	'accidentially\nbuy half of the auction house.\n\n:)'] = '欢迎使用AuctionFaster。\n\n诚挚地建议您，使用前先阅读一遍新手教程，'..
	'以免不小心买下半个拍卖场。\n\n:)'
L['Once you enter search query\nthis button will add it to\nthe favorites.'] = '查询的关键字或条目可以按这个按钮加入收藏。'
L['This button opens up filters.\nClick again to close.'] = '点击这里打开过滤选项。\n再次点击关闭。'
L['Search results.\n\nThere are 3 major shortcuts:\n\n'] = '搜索结果。\n\n有三个功能快捷键：\n\n'
L['Shift + Click - Instant buy\n'] = 'Shift + 点击 - 立刻购买\n'
L['Alt + Click - Add to queue\n'] = 'Alt + 点击 - 加到待购清单\n'
L['Ctrl + Click - Chain buy\n'] = 'Ctrl + 点击 - 批量购买'
L['Your favorites\nClicking on the name will\ninstanty search for this query.\n\n'] = '你的收藏\n点击即可马上搜索。\n\n'
L['Click delete button to remove.'] = '点击删除按钮以移除。'
L['Chain buy will add all auctions\nfrom the first one you select\nto the bottom '] = '批量购买会从你选中的拍卖条目开始，\n从上而下'
L['of the list\nto the Buy Queue.\n\n'] = '将拍卖列表全部加入待购清单。\n\n'
L['You will still need to confirm them.'] = '你仍要一个个确认才会购买。'
L['Status of the current buy queue\n\nQty will show you actual quantity\n'] = '显示批量购买的进度，\n\n批量购买界面上的“数量”会显示你即将购买的那项拍卖总共堆叠了几个物品。\n'
L['and progress bar will show\nthe amount of auctions.'] = '这里的“拍卖”进度条则显示待购条目的数量。'
L['Minimal amount of quantity\nyou are interested in.\n\n'] = '你想搜索的最小堆叠数量。'
L['This is used by two buttons on the left.'] = '这个数值会作用在左边两个按钮的功能上。'
L['Adds all auctions to the queue that has at least the amount of quantity entered'] = '将高于“最小堆叠数量”的拍卖条目全部加入待购清单，'
L[' in the box on the right'] = '数量就是你在右边输入框设置的值'
L['Finds the first auction '] = '寻找拍卖中'
L['across all the pages'] = '该物品所有'
L[' that meets the minimum quantity\n\n'] = '符合“最小堆叠数量”的条目。\n'
L['You need to enter a search query first'] = '你必需先输入要搜索的东西才能进一步按数量过滤。'
L['Opens this tutorial again.\nHope you liked it\n\n:)\n\n'] = '点击这里可以重新打开新手教程。\n希望你喜欢它。\n\n:)\n\n'

-- buy UI
L['Buy Items'] = '买入'
L['AuctionFaster - Buy'] = 'AuctionFaster - 购买'
L['Search'] = '搜索'

L['Buy'] = '购买'
L['Skip'] = '跳过'
L['Close'] = '关闭'

-- sniper
L['Sniper'] = '抢标'
L['Auto Refresh'] = '自动刷新'
L['Refresh Interval'] = '刷新间隔'
L['More features\ncoming soon'] = '更多功能\n即将到来'

-- buy ui
L['Add to Queue'] = '加入队列'
L['Add With Min Stacks'] = '按最小堆叠加入'
L['Find X Stacks'] = '按堆叠过滤'
L['Min Stacks: '] = '最小堆叠'
L['Please select auction first'] = '请先选择一项拍卖品'
L['Enter a correct stack amount 1-200'] = '输入精确的堆叠数量，1-200'
L['Queue Qty: %d'] = '队列数量：%d'
L['Auctions: %d / %d'] = '拍卖：%d/%d'
L['Favorite Searches'] = '收藏的条目'
L['Name'] = '名字'
L['Seller'] = '出售者'
L['Qty'] = '数量'
L['Bid / Item'] = '每单位竞标价'
L['Buy / Item'] = '每单位直购价'
L['Chose your search criteria nad press "Search"'] = '选择搜索条件后按“搜索”'

-- sell functions
L['Qty: %d, Max Stacks: %d, Remaining: %d'] = '数量：%d，堆叠可售%d组，剩馀%d个'
L['Last scan: %s'] = '上次扫瞄：%s'
L['Stack Size (Max: %d)'] = '堆叠（最大%d）'
L['Please refresh auctions first'] = '请先按刷新，重整拍卖'
L['Yes'] = '是'
L['No'] = '否'
L['Incomplete sell'] = '散装零售'
L['You still have %d of %s Do you wish to sell rest?'] = '你还有%d个%s，要把剩下的也卖掉吗？'

-- sell info pane
L['Auction Info'] = '拍卖信息'
L['Deposit: %s'] = '保证金：%s'
L['# Auctions: %d'] = '上架：%d组'
L['Duration: %s'] = '持续时间：%s'
L['Historical Data'] = '历史纪录'
L['Per auction: %s'] = '每组：%s'
L['No historical data available for: '] = '没有关于%s的历史纪录可查阅。'
L['Lowest Buy'] = '最低购买价'
L['Trend Lowest Buy'] = true;
L['Average Buy'] = true;
L['Trend Average Buy'] = true;
L['Highest Buy'] = '最高购买价'
L['Test Line'] = true;
L['Historical Data: '] = '历史纪录：'

-- sell item settings
L['Item Settings'] = '物品设置'
L['No Item selected'] = '尚未选择物品'
L['Remember Stack Settings'] = '记住堆叠设置'
L['Remember Last Price'] = '记住上次价格'
L['Always Undercut'] = '总是自动压价'
L['Use Custom Duration'] = '自订拍卖时间'
L['12h'] = '12小时'
L['24h'] = '24小时'
L['48h'] = '48小时'
L['days ago'] = '天前'
L['hours ago'] = '小時前'
L['minutes ago'] = '分鐘前'
L['Pricing Model'] = '压价模式'
L['If there is no auctions of this item,'] = '如果要上架时，拍卖场里没有你先前上架的物品作为出价参考，'
L['remember last price.'] = '就按上次上架的价格出售。'
L['Your price will be overriden'] = '如果勾选了“总是自动压价”，'	-- switch these two translate to keep chinese word order correct.
L['if "Always Undercut" options is checked!'] = '你记住的价格会被复盖。' -- switch translate for previous entry to keep chinese word order correct.
L['Checking this option will make\nAuctionFaster remember how much\n' ..
	'stacks you wish to sell at once\nand how big is stack'] = '启用这个选项会使\nAuctionFaster记住你每次要上架的每组堆叠与组数'
L['By default, AuctionFaster always undercuts price,\neven if you toggle "Remember Last Price"\n'..
	'If you uncheck this option AuctionFaster\nwill never undercut items for you'] = 'AuctionFaster会自动压价，使上架的价格永远是最低价，就算你勾选了“记住上次价格”也一样。\n如果你取消这项，Auction Faster就不再替你自动压价。'

-- sell tutorial
L['Welcome to AuctionFaster.\n\nI recommend checking out sell tutorial at least once before you accidentally sell your precious goods.\n\n:)'] = '欢迎使用Auction Faster。\n\n诚挚地建议您，为了避免误卖贵重物品，使用前先阅读一遍新手教程。'
L['Here is the list of all inventory items you can sell, no need to drag anything.\n\n'] = '这是你行囊中可出售物品的清单，不需要拖曳任何东西，它们会自动显示在这里。\n\n'
L['After you select item, AuctionFaster will automatically make a scan of first page and undercut set bid/buy according to price model selected.'] = '当你选择一样物品，AuctionFaster会自动扫瞄该物品的拍卖列表，然后根据压价模式计算出售价。'
L['Here you will see selected item. Max stacks means how much of stacks can you sell according to your setting. Remaining means how much quantity will still stay in bag after selling item.'] = '你会在这里看见刚才选择的物品。“堆叠可售”的数量指的是按你设置的堆叠可以出售几叠。“剩馀”的数量指的是扣除那些预计要出售的数量后，包里还剩下多少个。'
L['AuctionFaster keeps auctions cache for about 10 minutes, you can see when last real scan was performed.\n\n'] = 'AuctionFaster会自动保留拍卖搜索结果缓存大约十分钟，你可以看到上次执行实时扫瞄的时间。'
L['You can click Refresh Auctions to scan again'] = '你可以点击“刷新拍卖”来重新扫瞄。'
L['Your bid price '] = '你的竞标价'
L['per one item.'] = '每单位（每一个）'	-- they should be a whole sentence: "Your bid price per one item."/"Your buyout price per one item.". or will make a bad grammer in asia launguagem even lost punctuation. 
L['AuctionFaster understands a lot of money formats'] = 'AuctionFaster可以辨识多种货币格式'
L[', for example:\n\n' .. '5g 6s 19c\n5g6s86c\n999s 50c\n3000s\n9000000c'] = '，例如：\n\n' .. '5g 6s 19c\n5g6s86c\n999s 50c\n3000s\n9000000c'
L['Your buyout price '] = '你的直购价'
L[' Same money formats as bid per item.'] = '，使用和竞拍价相同的格式输入。'
L['Maximum number of stacks you wish to sell.\n\n'] = '你要按设置的堆叠出售几组。\n\n'
L['Set this to 0 to sell everything'] = '设为0就是全部出售。'
L['This opens up item settings.\nClick again to close.\n\n'] = '点击这里打开物品设置。\n再次点击关闭。\n\n'
L['Hover over checkboxes to see what the options are.\n\n'] = '把鼠标移到选项上，看看它们的功能与说明。\n\n'
L['Those settings are per specific item'] = '这是针对指定物品的额外上架设置'
L['This opens auction informations:\n\n' ..
	'- Total auction buy price.\n' ..
	'- Deposit cost.\n' ..
	'- Number of auctions\n' ..
	'- Auction duration\n\n'] = '点击这里打开拍卖信息：\n\n' ..
	'每一组的售价\n' ..
	'花费的保证金\n' ..
	'将要上架几组\n' ..
	'拍卖持续时间\n\n'
L['This will change dynamically when you change stack size or max stacks.'] = '这会随着你调整出售的堆叠大小或上架组数而动态更改。'
L['Here is a list of auctions of currently selected item.\n'] = '这是你选择的物品当前的拍卖列表。\n'
L['You can be sure your item will be cheapest.\n'] = '你可以对照价格，确定物品将会以最低价出售。\n'
L['These are always sorted by lowest price per item.'] = '这个列表总是按物品单价由低至高排列。'
L['This button allows you to buy selected item. Useful for restocking.'] = '点击这个按钮可以购买选定的项目，使扫货更方便。'
L['Posts %s of selected item regardless of your\n"# Stacks" settings'] = '只上架%s物品，而不管你对“出售几组”的设置。'
L['Posts %s of selected item according to your\n"# Stacks" settings'] = '根据你对“出售几组”的设置，将%s物品上架。'
L['one auction'] = '一项'
L['all auctions'] = '全部'
L['Once you close this tutorial it won\'t show again unless you click it'] = '关闭教程就不再显示，除非你再次点击这个按钮。'

-- sell ui
L['Sell Items'] = '卖出'
L['AuctionFaster - Sell'] = 'AuctionFaster - 出售'
L['Refresh inventory'] = '刷新库存'
L['Sort settings'] = '排序设置'
L['Sort by'] = '分类'
L['Name'] = '名字'
L['Price'] = '价格'
L['Quality'] = '品质'
L['Direction'] = '排序'
L['Ascending'] = '升序'
L['Descending'] = '降序'
L['Filter items'] = '过滤物品'
L['Bid Per Item'] = '每单位竞标价'
L['Buy Per Item'] = '每单位直购价'
L['Stack Size'] = '堆叠'
L['# Stacks'] = '出售几组' -- this make me and other confuse, actually transelate as "组", it means a set/packet, 出售几组 means how many sets wanna sell as that stack
L['Refresh Auctions'] = '刷新拍卖'
L['Post All'] = '上架全部'
L['Post One'] = '上架一个'
L['Lvl'] = '等级'	-- qty and stack and lvl in list are invisible in asia client after translate because not enough space for them.