module 'aux.locale'

-- 本地化：英文为隐式回退（key 本身即英文），故仅非英文语言需要填写条目。
-- 缺失翻译时 M.t 返回 key 本身，避免界面出现空白。
local locale = GetLocale()

local translations = {}

if locale == 'zhCN' or locale == 'zhTW' then
	local L = translations

	-- 标签页
	L['Search']   = '搜索'
	L['Post']     = '上架'
	L['Auctions'] = '拍卖'
	L['Bids']     = '竞价'

	-- 主窗口
	L['Close']       = '关闭'
	L['Blizzard UI'] = '暴雪界面'

	-- 启动提示 (aux-addon.lua)
	L['loaded - /aux'] = '已加载 - /aux'
	L['aux now comes with a new blizz-like theme. If you wish to switch between themes, use /aux theme'] =
		'aux 现已附带新的类暴雪主题。如需切换主题，请使用 /aux theme'

	-- 搜索标签页 (tabs/search/frame.lua)
	L['Range:']         = '范围：'
	L['Real Time']      = '实时'
	L['Pause']          = '暂停'
	L['Resume']         = '继续'
	L['Search Results'] = '搜索结果'
	L['Saved Searches'] = '保存的搜索'
	L['Filter Builder'] = '筛选器'
	L['Bid']            = '竞价'
	L['Buyout']         = '一口价'
	L['Clear']          = '清除'
	L['Favorite']       = '收藏'
	L['Export']         = '导出'
	L['Import']         = '导入'
	L['Name']           = '名称'
	L['Exact']          = '精确匹配'
	L['Level Range']    = '等级范围'
	L['Usable']         = '可用'
	L['Item Class']     = '物品类别'
	L['Item Subclass']  = '物品子类别'
	L['Item Slot']      = '物品部位'
	L['Min Quality']    = '最低品质'
	L['Component']      = '部件'
	L['Auto']           = '自动'
	L['Favorite Searches'] = '收藏的搜索'
	L['Recent Searches']   = '最近的搜索'
	L['Post Filter:']   = '后置筛选：'

	-- 搜索弹窗 (tabs/search/core.lua)
	L['Table full!\nFurther results from this search will still be processed but no longer displayed in the table.'] =
		'表格已满！\n此搜索的后续结果仍会被处理，但不再显示在表格中。'
	L['Ok'] = '确定'

	-- 已保存搜索右键菜单 (tabs/search/saved.lua)
	L['Enable Auto Buy']  = '启用自动购买'
	L['Disable Auto Buy'] = '禁用自动购买'
	L['Enable Auto Bid']  = '启用自动竞价'
	L['Disable Auto Bid'] = '禁用自动竞价'
	L['Move Up']   = '上移'
	L['Move Down'] = '下移'
	L['Delete']    = '删除'

	-- 状态栏 / 扫描 / 错误 (results.lua, saved.lua, util/scan.lua, auctions/bids/post core.lua)
	L['Scanning last page ...'] = '正在扫描最后一页…'
	L['Scan paused']             = '扫描已暂停'
	L['Resuming scan...']        = '正在继续扫描…'
	L['Scanning auctions...']    = '正在扫描拍卖…'
	L['Scan complete']           = '扫描完成'
	L['Scan aborted']            = '扫描已中止'
	L['Searching auction...']    = '正在搜索拍卖…'
	L['Auction found']           = '已找到拍卖'
	L['Auction not found']       = '未找到拍卖'
	L['Invalid filter:']         = '无效的筛选器：'
	L['Invalid auto buy filter:'] = '无效的自动购买筛选器：'
	L['Invalid auto bid filter:'] = '无效的自动竞价筛选器：'
	L['Error: The real time mode does not support multi-queries']  = '错误：实时模式不支持多重查询'
	L['Error: The real time mode does not support page ranges']    = '错误：实时模式不支持分页范围'
	L['Error: Auto Buy does not support multi-queries']            = '错误：自动购买不支持多重查询'
	L['Error: Auto Buy does not support Blizzard filters']         = '错误：自动购买不支持暴雪筛选器'
	L['Error: Auto Bid does not support multi-queries']            = '错误：自动竞价不支持多重查询'
	L['Error: Auto Bid does not support Blizzard filters']         = '错误：自动竞价不支持暴雪筛选器'

	-- 含占位符的格式串（保持 %d/%s 顺序一致）
	L['Scanning %d / %d (Page %d / %d)'] = '正在扫描 %d / %d（第 %d / %d 页）'
	L['Scanning Page %d / %d']           = '正在扫描第 %d / %d 页'
	L['Scanning (Page %d / %d)']         = '正在扫描（第 %d / %d 页）'
	L['Fetching item %d.']               = '正在获取物品 %d。'
	L['(Total Cost: ']                   = '（总成本：'
	L[')']                               = '）'
	L['  %s%% %s (%s-%s)']               = '  %s%% %s（%s-%s）'  -- 分解分布行

	-- 物品提示 (core/tooltip.lua) —— Today 行的百分比后缀
	L[' (%s)'] = ' （%s）'

	-- 上架标签页 (tabs/post/frame.lua, tabs/post/core.lua)
	L['Show hidden items']    = '显示隐藏物品'
	L['Refresh']              = '刷新'
	L['Stack Size']           = '堆叠数量'
	L['Stack Count']          = '堆叠组数'
	L['Duration']             = '持续时间'
	L['Hide this item']       = '隐藏此物品'
	L['Unit Starting Price']  = '单位起拍价'
	L['Unit Buyout Price']    = '单位一口价'
	L['No item selected']     = '未选择物品'
	L['Deposit: ']            = '保证金：'
	L['Unit Vendor Price: N/A']  = '单位商人价格：不可用'
	L['Unit Vendor Price: None'] = '单位商人价格：无'
	L['Unit Vendor Price: ']     = '单位商人价格：'
	L['6 Hours']  = '6 小时'
	L['24 Hours'] = '24 小时'
	L['72 Hours'] = '72 小时'

	-- 拍卖标签页 (tabs/auctions/frame.lua)
	L['Cancel'] = '取消'

	-- 购买汇总 (gui/purchase_summary.lua)
	L['Purchase Summary'] = '购买汇总'
	L['Item']             = '物品'
	L['Count']            = '数量'
	L['Gold Spent']       = '花费金币'

	-- 拍卖列表列标题 (gui/auction_listing.lua)
	L['Lvl']                       = '等级'
	L['Stack\nSize']               = '堆叠\n数量'
	L['Time\nLeft']                = '剩余\n时间'
	L['Time Left']                 = '剩余时间'
	L['Auction Bid\n(per item)']   = '拍卖竞价\n（单价）'
	L['Auction Bid\n(per stack)']  = '拍卖竞价\n（每组）'
	L['Auction Buyout\n(per item)']   = '拍卖一口价\n（单价）'
	L['Auction Buyout\n(per stack)']  = '拍卖一口价\n（每组）'
	L['Auction Buyout (per item)']    = '拍卖一口价（单价）'
	L['% Hist.\nValue']            = '历史\n价值%'
	L['% Hist. Value']             = '历史价值%'
	L['Seller']                    = '卖家'
	L['High Bidder']               = '最高竞拍者'
	L['No Bids']                   = '无竞价'
	L['Status']                    = '状态'
	L['Outbid']                    = '被超出'
	L['Double-click to collapse this item and show only the cheapest auction.'] =
		'双击折叠此项，仅显示最便宜的拍卖。'
	L['Double-click to expand this item and show all the auctions.'] =
		'双击展开此项，显示所有拍卖。'

	-- 物品提示信息 (core/tooltip.lua)
	L['Disenchants into:'] = '分解为：'
	L['Disenchant: ']      = '分解：'
	L['Vendor Buy ']       = '商人售价 '
	L['(limited): ']       = '（限量）：'
	L['Vendor: ']          = '商人收购：'
	L['Value: ']           = '价值：'
	L['Today: ']           = '今日：'

	-- 制作成本 (core/crafting.lua) — 见上方 '(Total Cost: %s)'

	-- 缓存 (core/cache.lua)
	L['Cache populated.'] = '缓存已填充。'

	-- 自动定价 (core/post.lua)
	L['autopricing recommends disenchanting!'] = '自动定价建议分解！'
	L['autopricing recommends vendoring!']      = '自动定价建议卖给商人！'
	L['insufficient data for autopricing!']     = '自动定价数据不足！'

	-- 斜杠命令状态反馈 (core/slash.lua) —— 命令名/用法行保持英文，仅翻译描述与提示
	L['on']  = '开'
	L['off'] = '关'
	L['undercutting ']                = '压价 '
	L['ignore owner ']                = '忽略卖家 '
	L['post stack ']                  = '上架堆叠 '
	L['post bid ']                    = '上架竞价 '
	L['post duration ']               = '上架持续时间 '
	L['crafting cost ']               = '制作成本 '
	L['tooltip value ']               = '提示价值 '
	L['tooltip daily ']               = '提示日均价 '
	L['tooltip merchant buy ']        = '提示商人售价 '
	L['tooltip merchant sell ']       = '提示商人收购 '
	L['tooltip disenchant value ']    = '提示分解价值 '
	L['tooltip disenchant distribution '] = '提示分解分布 '
	L['sharing ']            = '共享 '
	L['theme ']              = '主题 '
	L['show hidden ']        = '显示隐藏 '
	L['purchase summary ']   = '购买汇总 '
	L['Item cache cleared.'] = '物品缓存已清空。'
	L['Price cache cleared.'] = '价格缓存已清空。'
	L['A relog or reload is required for this change to take effect.'] =
		'此更改需要重登或重载界面才能生效。'
	L['Usage:'] = '用法：'

	-- 购物对比提示 (util/info.lua)
	L['Currently Equipped'] = '当前装备'

	-- 筛选器解析错误 (util/filter.lua) —— 与英文关键字拼接，混合可接受
	L['Invalid item name']    = '无效的物品名称'
	L['Invalid choice for ']  = '无效的选择：'
	L['Invalid input for ']   = '无效的输入：'
	L['. Expecting: ']        = '。期望：'
	L['Empty modifier']       = '空的修饰符'
	L['Malformed expression'] = '表达式格式错误'

	-- 按键绑定显示名 (localization.lua)
	L['Aux Post'] = '上架拍卖'
end

-- 翻译查找：命中返回译文，否则回退到 key 本身（即英文）。
M.t = function(key)
	return translations[key] or key
end
