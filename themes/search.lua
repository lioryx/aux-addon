module 'aux.tabs.search'
local aux=require 'aux'
local gui=require 'aux.gui'
local media=require 'aux.forever.media'
local W=require 'aux.forever.widgets'
local info=require 'aux.util.info'
local scan=require 'aux.core.scan'
local scan_util=require 'aux.util.scan'
local money=require 'aux.util.money'
local al=require 'aux.gui.auction_listing'
local L=require('aux.locale').t
local ui
local records={}
local scan_id, locate_id, generation, selection_version=0,0,0,0
local selected, found_index, detail_key, favorite_key
local active, incomplete, truncated, advanced=false,false,false,false
local category={}
local last_query, next_page, current_page, page_start_count, page_finished
local sort_column, sort_reverse=1,false
local groups={}

local function invalidate()
    selection_version=selection_version+1
    scan.abort(locate_id);locate_id=0;selected=nil;found_index=nil
    if ui then ui.bid:Disable();ui.buy:Disable() end
end
local function stop_scan()
    generation=generation+1
    scan.abort(scan_id);scan_id=0
    if active then
        incomplete=true
        if not page_finished and page_start_count then
            while getn(records)>page_start_count do tremove(records) end
        end
        next_page=(current_page or 0)+(page_finished and 1 or 0)
    end
    active=false
end
local function favorite_data()
    aux.realm_data.forever_favorites=aux.realm_data.forever_favorites or {}
    return aux.realm_data.forever_favorites
end
local function favorite(record)
    local data=favorite_data()
    if data[record.item_key] then data[record.item_key]=nil else
        local base=info.item(record.item_id)
        data[record.item_key]={item_key=record.item_key,item_id=record.item_id,name=record.name,query=base and base.name or record.name,link=record.link,texture=record.texture}
    end
end
local function shortcut(record)
    if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then ChatFrameEditBox:Insert(record.link);return true end
    if IsControlKeyDown() then DressUpItemLink(record.link);return true end
end
local function remove_record(record)
    for i,r in ipairs(records) do if r==record then tremove(records,i);break end end
end
local render
local function select_record(record)
    stop_scan();invalidate()
    if info.is_player(record.owner) then render();return end
    selected=record
    local version=selection_version
    local function valid() return version==selection_version and selected==record and ui.root:IsVisible() end
    locate_id=scan_util.find(record,ui.status,
        function() if valid() then invalidate();render() end end,
        function() if valid() then remove_record(record);invalidate();render() end end,
        function(index)
            if not valid() then return end
            found_index=index
            if not record.high_bidder then ui.bid:Enable() end
            if record.buyout_price>0 then ui.buy:Enable() end
        end)
    render()
end
local function trade(buyout)
    local r=selected
    if not r or not found_index or aux.bid_in_progress() then return end
    local present=false
    for _,v in ipairs(records) do if v==r then present=true;break end end
    if not present then invalidate();render();return end
    if not scan_util.test(r,found_index) then select_record(r);return end
    local amount=buyout and r.buyout_price or r.bid_price
    if amount<=0 or info.is_player(r.owner) then return end
    if GetMoney()<amount then ui.status:set_text(L'Not enough money');return end
    if not buyout and r.high_bidder then return end
    local index=found_index
    invalidate()
    aux.place_bid('list',index,amount,function()
        if not ui.root:IsVisible() then return end
        if buyout or (r.buyout_price>0 and amount>=r.buyout_price) then remove_record(r) else info.bid_update(r) end
        render()
    end)
end
render=function()
    if not ui then return end
    groups={}
    for _,r in ipairs(records) do
        local g=groups[r.item_key]
        if not g then g={record=r,count=0,buy_count=0,records={}};groups[r.item_key]=g end
        tinsert(g.records,r)
        if not info.is_player(r.owner) then
            g.count=g.count+(r.count or 1)
            if r.buyout_price>0 then
                local unit=r.buyout_price/(r.count or 1)
                g.price=math.min(g.price or unit,unit)
                g.buy_count=g.buy_count+(r.count or 1)
            end
        end
    end
    local rows={}
    if detail_key then
        local g=groups[detail_key]
        if g then
            ui.item_name:SetText(g.record.link)
            ui.icon:SetTexture(g.record.texture)
            ui.available:SetText(L'Buyable quantity: '..g.buy_count)
            media.set_icon(ui.favorite,favorite_data()[detail_key] and 'star-on' or 'star-off')
            for _,r in ipairs(g.records) do
                tinsert(rows,{record=r,link=r.link,cells={{money=r.blizzard_bid},r.buyout_price>0 and {money=r.buyout_price} or L'Bid only',r.count,al.time_left(r.duration)}})
            end
            table.sort(rows,function(a,b)
                local x,y=a.record,b.record
                local ap=x.buyout_price>0 and x.buyout_price or aux.huge
                local bp=y.buyout_price>0 and y.buyout_price or aux.huge
                if ap==bp then return x.bid_price<y.bid_price end
                return ap<bp
            end)
        else ui.item_name:SetText(L'No items found');ui.available:SetText('');ui.icon:SetTexture(nil) end
        ui.details:SetData(rows);ui.summary:Hide();ui.detail:Show()
    else
        for key,g in pairs(groups) do
            if g.count>0 then
                tinsert(rows,{group=g,key=key,link=g.record.link,icon={texture=g.record.texture,column=2},cells={g.price and {money=g.price} or L'Bid only',g.record.link..' ('..(g.record.level or 0)..')',g.count}})
            end
        end
        table.sort(rows,function(a,b)
            local x,y
            if sort_column==2 then x,y=a.group.record.name,b.group.record.name
            elseif sort_column==3 then x,y=a.group.count,b.group.count
            else x,y=a.group.price or aux.huge,b.group.price or aux.huge end
            if x==y then return a.key<b.key end
            if sort_reverse then return x>y end
            return x<y
        end)
        ui.summary:SetData(rows);ui.detail:Hide();ui.summary:Show()
    end
    ui.empty:SetText(getn(rows)==0 and (active and L'Scanning auctions...' or L'No items found') or '')
    if active then ui.search:SetText(L'Pause') else ui.search:SetText(L'Search') end
    if incomplete and last_query and not truncated then ui.resume:Show() else ui.resume:Hide() end
    ui.scope:SetText(truncated and L'Result limit reached: showing scanned auctions only' or (active or incomplete) and L'Scanned results only' or '')
    if selected then ui.details:render() end
end
local function run_query(query,resume)
    stop_scan();invalidate();ui.favorites:Hide();ui.results:Show()
    if not resume then records={};detail_key=nil;next_page=0;truncated=false;ui.summary.offset=0 end
    last_query=query;incomplete=false;active=true
    local token=generation
    local request={blizzard_query=aux.copy(query.blizzard_query),validator=query.validator}
    request.blizzard_query.first_page=resume and next_page or 0
    current_page=request.blizzard_query.first_page;page_finished=false;page_start_count=getn(records)
    scan_id=scan.start{
        type='list',ignore_owner=false,queries={request},
        on_page_loaded=function(page,total)
            if token~=generation then return end
            current_page=request.blizzard_query.first_page+page-1;page_start_count=getn(records);page_finished=false
            ui.status:update_status(page/math.max(1,total),0)
            ui.status:set_text(format(L'Scanning Page %d / %d',page,total))
        end,
        on_auction=function(r)
            if token~=generation then return end
            if getn(records)<2000 then tinsert(records,r) else truncated=true;scan.stop() end
        end,
        on_page_scanned=function() if token==generation then page_finished=true;render() end end,
        on_complete=function()
            if token~=generation then return end
            active=false;incomplete=truncated;ui.status:update_status(1,1);ui.status:set_text(L'Scan complete');render()
        end,
        on_abort=function() if token==generation then active=false;incomplete=true;render() end end
    }
    render()
end
local function search()
    if active then stop_scan();ui.status:set_text(L'Scan paused');render();return end
    local minlevel,maxlevel=tonumber(ui.min:GetText()),tonumber(ui.max:GetText())
    if minlevel and maxlevel and minlevel>maxlevel then ui.status:set_text(L'Invalid level range');return end
    local qualities={}
    for q,c in pairs(ui.qualities) do qualities[q]=c:GetChecked() and true or false end
    local key=favorite_key
    local query={blizzard_query={name=ui.keyword:GetText(),class=category.class,subclass=category.subclass,slot=category.slot,min_level=minlevel,max_level=maxlevel,usable=ui.usable:GetChecked() and true or nil},
        validator=function(r) return qualities[r.quality] and (not key or key==r.item_key) end}
    ui.popup:Hide();run_query(query)
end
local function show_favorites()
    stop_scan();invalidate();ui.results:Hide();ui.favorites:Show()
    local rows={}
    for key,r in pairs(favorite_data()) do tinsert(rows,{record=r,cells={r.link or r.name},link=r.link,icon={texture=r.texture,column=1}}) end
    table.sort(rows,function(a,b) return a.record.name<b.record.name end)
    ui.favorite_list:SetData(rows)
    ui.tip:SetText(getn(rows)==0 and L'Right-click an item to favorite it. Favorites appear here when you open the auction house.' or '')
end
local function categories()
    local rows={{cells={ALL},value={}}}
    for c,name in ipairs({GetAuctionItemClasses()}) do
        tinsert(rows,{cells={name},value={class=c}})
        if category.class==c then
            for s,sub in ipairs({GetAuctionItemSubClasses(c)}) do
                tinsert(rows,{cells={sub},indent=12,value={class=c,subclass=s}})
                if category.subclass==s then
                    for k,slot in ipairs({GetAuctionInvTypes(c==2 and 2 or 0,s)}) do
                        tinsert(rows,{cells={_G[slot] or slot},indent=24,value={class=c,subclass=s,slot=k}})
                    end
                end
            end
        end
    end
    ui.categories:SetData(rows)
end
function forever_advanced(enable)
    if not ui then return end
    stop_scan();invalidate();scan_abort_advanced();advanced=enable and true or false
    if advanced then ui.root:Hide();frame:Show();ui.advanced_back:Show();update_search_listings();update_filter_display()
    else frame:Hide();ui.advanced_back:Hide();ui.root:Show();render() end
end
function forever_open()
    scan_abort_advanced()
    advanced=false;frame:Hide();ui.advanced_back:Hide();ui.root:Show();show_favorites()
end
function forever_close()
    if not ui then return end
    stop_scan();invalidate();scan_abort_advanced();ui.root:Hide();ui.advanced_back:Hide();ui.popup:Hide();frame:Hide()
end
function forever_item_search(item)
    forever_advanced(false)
    category={};favorite_key=nil;categories();ui.keyword:SetText(item.name);search()
end
function aux.handle.CLOSE() if gui.is_forever() then forever_close() end end
function aux.handle.INIT_UI()
    if not gui.is_forever() then return end
    ui={qualities={}}
    local root=CreateFrame('Frame',nil,gui.page_parent());root:SetAllPoints();ui.root=root
    root:SetScript('OnHide',function() ui.popup:Hide() end)
    root:SetScript('OnUpdate',function()
        if aux.bid_in_progress() then ui.bid:Disable();ui.buy:Disable();return end
        if selected and found_index and not aux.bid_in_progress() and not scan_util.test(selected,found_index) then invalidate();ui.status:set_text(L'Auction not found') end
    end)
    ui.keyword=W.input(root,300);ui.keyword:SetPoint('TOPLEFT',240,-7);ui.keyword:SetScript('OnEnterPressed',search)
    ui.keyword:SetTextInsets(26,8,2,2)
    local glass=ui.keyword:CreateTexture(nil,'OVERLAY');glass:SetTexture(media.path('search'));gui.set_size(glass,16,16);glass:SetPoint('LEFT',6,0)
    local placeholder=W.text(ui.keyword,L'Search',14);placeholder:SetTextColor(.5,.48,.44);placeholder:SetPoint('LEFT',26,0)
    ui.keyword:SetScript('OnTextChanged',function() if this.forever_focused then favorite_key=nil end;if this:GetText()=='' then placeholder:Show() else placeholder:Hide() end end)
    ui.search=W.button(root,L'Search',150,search);ui.search:SetPoint('TOPRIGHT',-5,-5)
    ui.filter=W.tab_button(root,L'Filters',125,function() if ui.popup:IsShown() then ui.popup:Hide() else ui.popup:Show() end end)
    ui.filter:SetPoint('RIGHT',ui.search,'LEFT',-8,0)
    ui.star=W.icon_button(root,'star-on',28,show_favorites);ui.star:SetPoint('RIGHT',ui.keyword,'LEFT',-12,0)
    local adv=W.tab_button(root,L'Advanced',100,function() forever_advanced(true) end);adv:SetPoint('TOPLEFT',68,-5)
    ui.advanced_back=W.button(frame,L'Back to browse',130,function() forever_advanced(false) end)
    ui.advanced_back:SetPoint('TOPRIGHT',aux.frame,'TOPRIGHT',-54,-40);ui.advanced_back:Hide()
    local sidebar=W.panel(root);sidebar:SetPoint('TOPLEFT',0,-43);sidebar:SetPoint('BOTTOMLEFT',0,0);sidebar:SetWidth(190)
    ui.categories=W.list(sidebar,{{name=L'Item Class',width=1}},function(row)
        category=row.value;favorite_key=nil;categories()
    end,{headers=false});ui.categories:SetPoint('TOPLEFT',4,-3);ui.categories:SetPoint('BOTTOMRIGHT',-4,3)
    ui.categories.selected=function(row) return row.value.class==category.class and (not row.value.subclass or row.value.subclass==category.subclass and (not row.value.slot or row.value.slot==category.slot)) end
    local results=W.panel(root);results:SetPoint('TOPLEFT',198,-43);results:SetPoint('BOTTOMRIGHT',0,0);ui.results=results
    ui.empty=W.text(results,'',16);ui.empty:SetPoint('TOP',0,-110)
    ui.summary=W.list(results,{{name=L'Price',width=.25},{name=L'Name',width=.62},{name=L'Available',width=.13}},function(row,button)
        if shortcut(row.group.record) then return end
        if button=='RightButton' then favorite(row.group.record);render();return end
        invalidate();detail_key=row.key;render()
    end);ui.summary:SetPoint('TOPLEFT',6,-5);ui.summary:SetPoint('BOTTOMRIGHT',-6,5)
    ui.summary.sort_column=1
    ui.summary.sort=function(column) if sort_column==column then sort_reverse=not sort_reverse else sort_column=column;sort_reverse=false end;render() end
    ui.detail=CreateFrame('Frame',nil,results);ui.detail:SetAllPoints()
    local back=W.button(ui.detail,L'Back',90,function() invalidate();detail_key=nil;render() end);back:SetPoint('TOPLEFT',8,-8)
    local refresh=W.icon_button(ui.detail,'refresh',28,function() if last_query then run_query(last_query) end end);refresh:SetPoint('TOPRIGHT',-8,-8)
    ui.available=W.text(ui.detail,'',14);ui.available:SetPoint('RIGHT',refresh,'LEFT',-10,0)
    ui.icon=ui.detail:CreateTexture(nil,'ARTWORK');gui.set_size(ui.icon,48,48);ui.icon:SetPoint('TOPLEFT',18,-50)
    ui.favorite=W.icon_button(ui.detail,'star-off',28,function() if groups[detail_key] then favorite(groups[detail_key].record);render() end end);ui.favorite:SetPoint('TOPRIGHT',-8,-55)
    ui.item_name=W.text(ui.detail,'',18);ui.item_name:SetPoint('TOPLEFT',ui.icon,'TOPRIGHT',12,0);ui.item_name:SetPoint('TOPRIGHT',-48,-50);ui.item_name:SetHeight(48)
    ui.details=W.list(ui.detail,{{name=L'Bid',width=.32},{name=L'Buyout',width=.32},{name=L'Quantity',width=.14},{name=L'Time Left',width=.22}},function(row,button)
        if shortcut(row.record) then return end
        if IsAltKeyDown() and selected==row.record then trade(button=='LeftButton');return end
        if button=='RightButton' then favorite(row.record);render();return end
        select_record(row.record)
    end);ui.details:SetPoint('TOPLEFT',8,-110);ui.details:SetPoint('BOTTOMRIGHT',-8,39)
    ui.details.selected=function(row) return row.record==selected end
    ui.buy=W.button(ui.detail,L'Buyout',110,function() trade(true) end);ui.buy:SetPoint('BOTTOMRIGHT',-8,6);ui.buy:Disable()
    ui.bid=W.button(ui.detail,L'Bid',110,function() trade(false) end);ui.bid:SetPoint('RIGHT',ui.buy,'LEFT',-8,0);ui.bid:Disable()
    ui.status=gui.status_bar(root);ui.status:SetPoint('BOTTOMLEFT',198,-30);gui.set_size(ui.status,300,24)
    ui.resume=W.button(root,L'Resume',100,function() if last_query then run_query(last_query,true) end end);ui.resume:SetPoint('BOTTOMRIGHT',-38,-30);ui.resume:Hide()
    ui.scope=W.text(root,'',12);ui.scope:SetPoint('BOTTOMLEFT',510,-30);ui.scope:SetPoint('BOTTOMRIGHT',ui.resume,'BOTTOMLEFT',-8,0);ui.scope:SetHeight(24);ui.scope:SetJustifyH('RIGHT')
    ui.favorites=W.panel(root);ui.favorites:SetAllPoints(results)
    ui.favorite_list=W.list(ui.favorites,{{name=L'Favorite items',width=1}},function(row,button)
        if button=='RightButton' then favorite_data()[row.record.item_key]=nil;show_favorites();return end
        category={};categories();ui.keyword:SetText(row.record.query or row.record.name);favorite_key=row.record.item_key;search()
    end);ui.favorite_list:SetPoint('TOPLEFT',6,-5);ui.favorite_list:SetPoint('BOTTOMRIGHT',-6,5)
    ui.tip=W.text(ui.favorites,'',16);ui.tip:SetPoint('TOPLEFT',30,-100);ui.tip:SetPoint('TOPRIGHT',-30,-100);ui.tip:SetJustifyH('CENTER')
    ui.popup=W.panel(root);ui.popup:SetFrameStrata('DIALOG');gui.set_size(ui.popup,250,330);ui.popup:SetPoint('TOPRIGHT',ui.filter,'BOTTOMRIGHT',0,-5)
    local label=W.text(ui.popup,L'Level Range');label:SetPoint('TOPLEFT',16,-15)
    ui.min=W.input(ui.popup,80);ui.min:SetNumeric(true);ui.min:SetMaxLetters(3);ui.min:SetPoint('TOPLEFT',20,-42)
    ui.max=W.input(ui.popup,80);ui.max:SetNumeric(true);ui.max:SetMaxLetters(3);ui.max:SetPoint('LEFT',ui.min,'RIGHT',20,0)
    ui.usable=W.check(ui.popup,L'Usable',function() end);ui.usable:SetPoint('TOPLEFT',14,-77)
    for q=0,6 do local c=W.check(ui.popup,_G['ITEM_QUALITY'..q..'_DESC'] or tostring(q),function() end);c:SetPoint('TOPLEFT',14,-110-q*25);c:SetChecked(true);local color=ITEM_QUALITY_COLORS[q];if color then c.label:SetTextColor(color.r,color.g,color.b) end;ui.qualities[q]=c end
    local done=W.button(ui.popup,L'Close',90,function() ui.popup:Hide() end);done:SetPoint('BOTTOMRIGHT',-10,10)
    ui.popup:Hide();categories();root:Hide()
end

function M.forever_search_item(item) return forever_item_search(item) end
