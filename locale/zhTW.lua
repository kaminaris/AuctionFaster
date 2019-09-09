local L = LibStub('AceLocale-3.0'):NewLocale('AuctionFaster', 'zhTW');
if not L then return end

L['AuctionFaster - Historical Options'] = 'AuctionFaster - 歷史選項'
L['Enable Historical Data Collection'] = '啟用歷史紀錄'
L['Days to keep data (5-50)'] = '紀錄的天數，5至50天'
L['AuctionFaster - Pricing Options'] = 'AuctionFaster - 價格選項'
L['Historical Options'] = '歷史選項'
L['Pricing Options'] = '價格選項'
L['Maximum difference bid to buy (1-100%)'] = true;
L['AuctionFaster Options'] = 'AuctionFaster - 選項'
L['AuctionFaster'] = true;	-- maybe dont need to translate
L['Enable AuctionFaster'] = '啟用AuctionFaster'
L['Fast Mode'] = '快速模式'
L['Enable ToolTips'] = '啟用滑鼠提示'
L['12 Hours'] = '12小時'
L['24 Hours'] = '24小時'
L['48 Hours'] = '48小時'
L['Do not set'] = '不設定'
L['Sell Tab'] = '出售分頁'
L['Buy Tab'] = '購買分頁'
L['Wipe Item Cache'] = '清除物品暫存'
L['Reset Tutorials'] = '重置新手教學'
L['Auction Duration'] = '拍賣時間'
L['Set Default Tab'] = '預設開啟分頁'
L['Item cache wiped!'] = '物品暫存已清除！'
L['Tutorials reset!'] = '新手教學已重置！'
L['Top'] = '上方'
L['Top Right'] = '右上'
L['Right'] = '右方'
L['Bottom Right'] = '右下'
L['Bottom'] = '下方'
L['Bottom Left'] = '左下'
L['Left'] = '左方'
L['Top Left'] = '左上'
L['Sell Tab Settings'] = '出售分頁設定'
L['Enable ToolTips for Items'] = '啟用物品的滑鼠提示'
L['Tooltip Anchor'] = '滑鼠提示錨點'
L['Item Tooltip Anchor'] = '物品提示錨點'
L['Buy Tab Settings'] = '購買分頁設定'
L['Query failed, retrying: %d'] = '查詢失敗，重試 %d 次'
L['Cannot query AH. Please wait a bit longer or reload UI'] = '無法掃瞄拍賣行。請等一下或重載介面'
L['Could not pick up item from inventory'] = '無法從背包中選定物品'
L['Posting: %s for:\nper auction: %s\nper item: %s\n# stacks: %d stack size: %d'] = '上架%s：\n每組售價：%s\n單價：%3$s\n共出售%d組，每組堆疊%d個。'

-- chain buy
L['Chain Buy'] = '批量購買'
L['Qty: %d'] = '數量：%d'
L['Per Item: %s'] = '單價：%s'
L['Total: %s'] = '總價：%s'
L['Bought so far: %d'] = '已購買%d個'
L['Queue'] = true;
L['Fast Mode - AuctionFaster will NOT wait until you actually buy an item.\n\n'..
	'This may result in inaccurate amount of bought items and some missed auctions.\n' ..
	'|cFFFF0000Use this only if you don\'t care about how much you will buy and want to buy fast.|r'] = '快速模式\n啟用後，AuctionFaster不會等到你「確定買到了」才顯示下一項，按下購買按鈕就直接顯示下一項。\n'..'這可能或錯過某些商品。\n\n'..'|cFFFF0000只在你不在乎買價和數量，只想快速掃貨時使用。|r'
	
-- item cache
L['Invalid cache key'] = '無效關鍵字'

-- pricing
L['LowestPrice'] = '最低價格'
L['WeightedAverage'] = '平均價格'
L['StackAware'] = '忽略散裝'
L['StandardDeviation'] = '標準偏差'
L['No auctions found'] = '沒有找到拍賣品'
L['No auction found with minimum quantity: %d'] = '未找到符合最小堆疊數量為%d的拍賣品'
L['Tooltips enabled'] = '啟用滑鼠提示'
L['Tooltips disabled'] = '停用滑鼠提示'
L['Lowest Bid: '] = '最低競標價'
L['Lowest Buy: '] = '最低購買價'
L['Filters'] = '過濾條件'
L['Exact Match'] = '精確符合'
L['Level from'] = '等級自'
L['Level to'] = '等級至'
L['Sub Category'] = '子類別'
L['Category'] = '類別'
L['No query was searched before'] = '尚未開始檢索'
L['Search in progress...'] = '正在搜尋...'
L['Nothing was found for this query.'] = '這個關鍵字沒有找到任何東西'
L['Pages: %d'] = '第%d頁'
L['Queue Qty: %d'] = '隊列中：%d'
L['Please select item first'] = '請先選定物品'
L['No auctions found with requested stack count: '] = '找不到符合最小堆疊數量的拍賣品'
L['Enter query and hit search button first'] = '先輸入要搜尋的物品關鍵字，然後點擊搜尋按鈕'
L['No auction found for minimum stacks: %d'] = '該物品找不到符合過濾條件為最小堆疊%d的項目。'
L['Addon Tutorial'] = '新手教學'
L['Addon settings'] = '設定選項'

-- buy tutorials
L['Welcome to AuctionFaster.\n\nI recommend checking out\ntutorial at least once\nbefore you ' ..
	'accidentially\nbuy half of the auction house.\n\n:)'] = '歡迎使用AuctionFaster。\n\n誠摯地建議您，使用前先閱讀一遍新手教學，'..
	'以免不小心買下半個拍賣場。\n\n:)'
L['Once you enter search query\nthis button will add it to\nthe favorites.'] = '查詢的關鍵字或條目可以按這個按鈕加入收藏。'
L['This button opens up filters.\nClick again to close.'] = '點擊這裡打開過濾選項。\n再次點擊關閉。'
L['Search results.\n\nThere are 3 major shortcuts:\n\n'] = '搜尋結果。\n\n有三個功能快捷鍵：\n\n'
L['Shift + Click - Instant buy\n'] = 'Shift + 點擊 - 立刻購買\n'
L['Alt + Click - Add to queue\n'] = 'Alt + 點擊 - 加到待購清單\n'
L['Ctrl + Click - Chain buy\n'] = 'Ctrl + 點擊 - 批量購買'
L['Your favorites\nClicking on the name will\ninstanty search for this query.\n\n'] = '你的收藏\n點擊即可馬上搜尋。\n\n'
L['Click delete button to remove.'] = '點擊刪除按鈕以移除。'
L['Chain buy will add all auctions\nfrom the first one you select\nto the bottom '] = '批量購買會從你選中的拍賣條目開始，\n從上而下'
L['of the list\nto the Buy Queue.\n\n'] = '將拍賣列表全部加入待購清單。\n\n'
L['You will still need to confirm them.'] = '你仍要一個個確認才會購買。'
L['Status of the current buy queue\n\nQty will show you actual quantity\n'] = '顯示批量購買的進度，\n\n批量購買介面上的「數量」會顯示你即將購買的那項拍賣總共堆疊了幾個物品。\n'
L['and progress bar will show\nthe amount of auctions.'] = '這裡的「拍賣」進度條則顯示待購條目的數量。'
L['Minimal amount of quantity\nyou are interested in.\n\n'] = '你想搜尋的最小堆疊數量。'
L['This is used by two buttons on the left.'] = '這個數值會作用在左邊兩個按鈕的功能上。'
L['Adds all auctions to the queue that has at least the amount of quantity entered'] = '將高於「最小堆疊數量」的拍賣條目全部加入待購清單，'
L[' in the box on the right'] = '數量就是你在右邊輸入框填的值。'
L['Finds the first auction '] = '尋找拍賣中'
L['across all the pages'] = '該物品所有'
L[' that meets the minimum quantity\n\n'] = '符合「最小堆疊數量」的條目。\n'
L['You need to enter a search query first'] = '你必需先輸入要搜尋的東西才能進一步按數量過濾。'
L['Opens this tutorial again.\nHope you liked it\n\n:)\n\n'] = '點擊這裡可以重新打開新手教學。\n希望你喜歡它。\n\n:)\n\n'

-- buy UI
L['Buy Items'] = '買入'
L['AuctionFaster - Buy'] = 'AuctionFaster - 購買'
L['Search'] = '搜尋'

L['Buy'] = '購買'
L['Skip'] = '跳過'
L['Close'] = '關閉'

-- sniper
L['Sniper'] = '搶標'
L['Auto Refresh'] = '自動更新'
L['Refresh Interval'] = '更新間隔'
L['More features\ncoming soon'] = '更多功能\n即將到來'

-- buy ui
L['Add to Queue'] = '加入隊列'
L['Add With Min Stacks'] = '按最小堆疊加入'
L['Find X Stacks'] = '按堆疊過濾'
L['Min Stacks'] = '最小堆疊'
L['Please select auction first'] = '請先選擇一項拍賣品'
L['Enter a correct stack amount 1-200'] = '輸入精確的堆疊數量，1-200'
L['Queue Qty: %d'] = '隊列數量：%d'
L['Auctions: %d / %d'] = '拍賣：%d/%d'
L['Favorite Searches'] = '收藏的條目'
L['Name'] = '名字'
L['Seller'] = '出售者'
L['Qty'] = '數量'
L['Bid / Item'] = '每單位競標價'
L['Buy / Item'] = '每單位直購價'
L['Chose your search criteria nad press "Search"'] = '選擇搜尋條件後按「搜尋」'

-- sell functions
L['Qty: %d, Max Stacks: %d, Remaining: %d'] = '數量：%d，堆疊可售%d組，剩餘%d個'
L['Last scan: %s'] = '上次掃瞄：%s'
L['Stack Size (Max: %d)'] = '堆疊（最大%d）'
L['Please refresh auctions first'] = '請先按更新，重整拍賣'
L['Yes'] = '是'
L['No'] = '否'
L['Incomplete sell'] = '散裝零售'
L['You still have %d of %s Do you wish to sell rest?'] = '你還有%d個%s，要把剩下的也賣掉嗎？'

-- sell info pane
L['Auction Info'] = '拍賣資訊'
L['Deposit: %s'] = '保證金：%s'
L['# Auctions: %d'] = '上架：%d組'
L['Duration: %s'] = '持續時間：%s'
L['Historical Data'] = '歷史紀錄'
L['Per auction: %s'] = '每組：%s'
L['No historical data available for: %s'] = '沒有關於%s的歷史紀錄。'
L['Lowest Buy'] = '最低購買價'
L['Trend Lowest Buy'] = true;
L['Average Buy'] = true;
L['Trend Average Buy'] = true;
L['Highest Buy'] = '最高購買價'
L['Test Line'] = true;
L['Historical Data: '] = '歷史紀錄：'

-- sell item settings
L['Item Settings'] = '物品設定'
L['No Item selected'] = '尚未選擇物品'
L['Remember Stack Settings'] = '記住堆疊設定'
L['Remember Last Price'] = '記住上次價格'
L['Always Undercut'] = '總是自動壓價'
L['Use Custom Duration'] = '自訂拍賣時間'
L['12h'] = '12小時'
L['24h'] = '24小時'
L['48h'] = '48小時'
L['days ago'] = '天前'
L['hours ago'] = '小時前'
L['minutes ago'] = '分鐘前'
L['Pricing Model'] = '壓價模式'
L['If there is no auctions of this item,'] = '如果要上架時，拍賣場裡沒有你先前上架的物品作為出價參考，'
L['remember last price.'] = '就按上次上架的價格出售。'
L['Your price will be overriden'] = '如果勾選了「總是自動壓價」，'	-- switch these two translate to keep chinese word order correct.
L['if "Always Undercut" options is checked!'] = '你記住的價格會被覆蓋。' -- switch translate for previous entry to keep chinese word order correct.
L['Checking this option will make\nAuctionFaster remember how much\n' ..
	'stacks you wish to sell at once\nand how big is stack'] = '啟用這個選項會使\nAuctionFaster記住你每次要上架的每組堆疊與組數'
L['By default, AuctionFaster always undercuts price,\neven if you toggle "Remember Last Price"\n'..
	'If you uncheck this option AuctionFaster\nwill never undercut items for you'] = 'AuctionFaster會自動壓價，使上架的價格永遠是最低價，就算你勾選了「記住上次價格」也一樣。\n如果你取消這項，AuctionFaster就不再替你自動壓價。'

-- sell tutorial
L['Welcome to AuctionFaster.\n\nI recommend checking out sell tutorial at least once before you accidentally sell your precious goods.\n\n:)'] = '歡迎使用AuctionFaster。\n\n誠摯地建議您，為了避免誤賣貴重物品，使用前先閱讀一遍新手教學。'
L['Here is the list of all inventory items you can sell, no need to drag anything.\n\n'] = '這是你行囊中可出售物品的清單，不需要拖曳任何東西，它們會自動顯示在這裡。\n\n'
L['After you select item, AuctionFaster will automatically make a scan of first page and undercut set bid/buy according to price model selected.'] = '當你選擇一樣物品，AuctionFaster會自動掃瞄該物品的拍賣列表，然後根據壓價模式計算出售價。'
L['Here you will see selected item. Max stacks means how much of stacks can you sell according to your setting. Remaining means how much quantity will still stay in bag after selling item.'] = '你會在這裡看見剛才選擇的物品。「堆疊可售」的數量指的是按你設定的堆疊可以出售幾疊。「剩餘」的數量指的是扣除那些預計要出售的數量後，包裡還剩下多少個。'
L['AuctionFaster keeps auctions cache for about 10 minutes, you can see when last real scan was performed.\n\n'] = 'AuctionFaster會自動保留拍賣搜尋結果暫存大約十分鐘，你可以看到上次執行實時掃瞄的時間。'
L['You can click Refresh Auctions to scan again'] = '你可以點擊「更新拍賣」來重新掃瞄。'
L['Your bid price '] = '你的競標價'
L['per one item.'] = '每單位（每一個）'	-- they should be a whole sentence: "Your bid price per one item."/"Your buyout price per one item.". or will make a bad grammer in asia launguagem even lost punctuation. 
L['AuctionFaster understands a lot of money formats'] = 'AuctionFaster可以辨識多種貨幣格式'
L[', for example:\n\n' .. '5g 6s 19c\n5g6s86c\n999s 50c\n3000s\n9000000c'] = '，例如：\n\n' .. '5g 6s 19c\n5g6s86c\n999s 50c\n3000s\n9000000c'
L['Your buyout price '] = '你的直購價'
L[' Same money formats as bid per item.'] = '，使用和競拍價相同的格式輸入。'
L['Maximum number of stacks you wish to sell.\n\n'] = '你要按設定的堆疊出售幾組。\n\n'
L['Set this to 0 to sell everything'] = '設為0就是全部出售。'
L['This opens up item settings.\nClick again to close.\n\n'] = '點擊這裡打開物品設定。\n再次點擊關閉。\n\n'
L['Hover over checkboxes to see what the options are.\n\n'] = '把滑鼠移到選項上，看看它們的功能與說明。\n\n'
L['Those settings are per specific item'] = '這是針對指定物品的額外上架設定'
L['This opens auction informations:\n\n' ..
	'- Total auction buy price.\n' ..
	'- Deposit cost.\n' ..
	'- Number of auctions\n' ..
	'- Auction duration\n\n'] = '點擊這裡打開拍賣資訊：\n\n' ..
	'每一組的售價\n' ..
	'花費的保證金\n' ..
	'將要上架幾組\n' ..
	'拍賣持續時間\n\n'
L['This will change dynamically when you change stack size or max stacks.'] = '這會隨著你調整出售的堆疊大小或上架組數而動態更改。'
L['Here is a list of auctions of currently selected item.\n'] = '這是你選擇的物品當前的拍賣列表。\n'
L['You can be sure your item will be cheapest.\n'] = '你可以對照價格，確定物品將以最低價出售。\n'
L['These are always sorted by lowest price per item.'] = '這個列表總是按物品單價由低至高排列。'
L['This button allows you to buy selected item. Useful for restocking.'] = '點擊這個按鈕可以購買選定的項目，使掃貨更方便。'
L['Posts %s of selected item regardless of your\n"# Stacks" settings'] = '只上架%s物品，而不管你對「出售幾組」的設定。'
L['Posts %s of selected item according to your\n"# Stacks" settings'] = '按照你對「出售幾組」的設定，將%s物品都上架。'
L['one auction'] = '一項'
L['all auctions'] = '全部'
L['Once you close this tutorial it won\'t show again unless you click it'] = '關閉教學就不再顯示，除非你再次點擊這個按鈕。'

-- sell ui
L['Sell Items'] = '賣出'
L['AuctionFaster - Sell'] = 'AuctionFaster - 出售'
L['Refresh inventory'] = '更新庫存'
L['Sort settings'] = '排序設定'
L['Sort by'] = '分類'
L['Name'] = '名字'
L['Price'] = '價格'
L['Quality'] = '品質'
L['Direction'] = '排序'
L['Ascending'] = '升序'
L['Descending'] = '降序'
L['Filter items'] = '過濾物品'
L['Bid Per Item'] = '每單位競標價'
L['Buy Per Item'] = '每單位直購價'
L['Stack Size'] = '堆疊'
L['# Stacks'] = '出售幾組' -- this make me and other confuse, actually transelate as "組", it means a set/packet, 出售幾組 means how many sets wanna sell as that stack
L['Refresh Auctions'] = '更新拍賣'
L['Post All'] = '上架全部'
L['Post One'] = '上架一個'
L['Lvl'] = '等級'	-- qty and lvl are invisible in asia client after translate because not enough space for them.