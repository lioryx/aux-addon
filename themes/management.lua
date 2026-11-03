module 'aux.forever.management'
local aux=require 'aux'
local gui=require 'aux.gui'
local W=require 'aux.forever.widgets'
local al=require 'aux.gui.auction_listing'
local money=require 'aux.util.money'
local L=require('aux.locale').t
local function cmp(field)
    return function(a,b,desc)
        local x,y=a[field] or 0,b[field] or 0
        if x==y then return false end
        if desc then return x>y end
        return x<y
    end
end
function M.build(kind,update,select,refresh)
    local u={}
    u.frame=CreateFrame('Frame',nil,gui.page_parent());u.frame:SetAllPoints();u.frame:SetScript('OnUpdate',update);u.frame:Hide()
    local sidebar=W.panel(u.frame);sidebar:SetPoint('TOPLEFT',0,-5);sidebar:SetPoint('BOTTOMLEFT',0,36);sidebar:SetWidth(190)
    local panel=W.panel(u.frame);panel:SetPoint('TOPLEFT',198,-5);panel:SetPoint('BOTTOMRIGHT',0,36)
    local holder=CreateFrame('Frame',nil,panel);holder:SetPoint('TOPLEFT',5,-5);holder:SetPoint('BOTTOMRIGHT',-5,5)
    local cols={
        {title=L'Item',width=.49,init=function(_,cell)
            cell.icon=cell:CreateTexture(nil,'ARTWORK');gui.set_size(cell.icon,18,18);cell.icon:SetPoint('LEFT',2,0)
            cell.text:ClearAllPoints();cell.text:SetPoint('TOPLEFT',24,0);cell.text:SetPoint('BOTTOMRIGHT',0,0)
        end,fill=function(cell,r) cell.icon:SetTexture(r.texture);cell.text:SetText(r.link) end,cmp=cmp('name')},
        {title=L'Bid',width=.19,align='RIGHT',init=function(_,cell) cell.money=W.amount(cell);cell.money:SetPoint('RIGHT',cell,'RIGHT',-4,0) end,fill=function(cell,r) cell.text:SetText('');cell.money:SetValue(r.blizzard_bid) end,cmp=cmp('blizzard_bid')},
        {title=L'Buyout',width=.2,align='RIGHT',init=function(_,cell) cell.money=W.amount(cell);cell.money:SetPoint('RIGHT',cell,'RIGHT',-4,0) end,fill=function(cell,r) if r.buyout_price>0 then cell.text:SetText('');cell.money:SetValue(r.buyout_price);cell.money:Show() else cell.money:Hide();cell.text:SetText(L'Bid only') end end,cmp=cmp('buyout_price')},
        {title=L'Time Left',width=.12,align='CENTER',fill=function(cell,r) cell.text:SetText(al.time_left(r.duration)) end,cmp=cmp('duration')}
    }
    u.listing=al.new(holder,20,cols);u.listing:SetSort(1,2,3,4);u.listing:Reset()
    u.status=gui.status_bar(u.frame);u.status:SetPoint('BOTTOMLEFT',198,3);gui.set_size(u.status,310,25)
    u.empty=W.text(panel,L'No items found',16);u.empty:SetPoint('TOP',0,-100)
    u.buy=W.button(u.frame,kind=='owner' and L'Cancel Auction' or L'Buyout',125,function() end);u.buy:SetPoint('BOTTOMRIGHT',0,2);u.buy:Disable()
    if kind~='owner' then u.bid=W.button(u.frame,L'Bid',110,function() end);u.bid:SetPoint('RIGHT',u.buy,'LEFT',-8,0);u.bid:Disable() end
    local refresh_button=W.icon_button(u.frame,'refresh',28,refresh);refresh_button:SetPoint('TOPRIGHT',aux.frame,'TOPRIGHT',-16,-42)
    local filter_key
    local latest={}
    u.sidebar=W.list(sidebar,{{name=kind=='owner' and L'Auctions' or L'Bids',width=1}},function(row)
        filter_key=row.key;u.listing:SetSelectedRecord();u:render(latest)
    end);u.sidebar:SetPoint('TOPLEFT',4,-4);u.sidebar:SetPoint('BOTTOMRIGHT',-4,4)
    u.sidebar.selected=function(row) return row.key==filter_key end
    function u:render(records)
        latest=records
        local groups={}
        for _,r in ipairs(records) do
            local g=groups[r.item_key]
            if not g then g={key=r.item_key,name=r.name,count=0};groups[r.item_key]=g end
            g.count=g.count+1
        end
        if filter_key and not groups[filter_key] then filter_key=nil end
        local side={{cells={ALL}}}
        local sorted={};for _,g in pairs(groups) do tinsert(sorted,g) end
        table.sort(sorted,function(a,b) return a.name<b.name end)
        for _,g in ipairs(sorted) do tinsert(side,{key=g.key,cells={g.name..' ('..g.count..')'}}) end
        self.sidebar:SetData(side)
        local visible={};for _,r in ipairs(records) do if not filter_key or r.item_key==filter_key then tinsert(visible,r) end end
        self.listing:SetDatabase(visible)
        if getn(visible)==0 then self.empty:Show() else self.empty:Hide() end
    end
    local remove=u.listing.RemoveAuctionRecord
    function u.listing:RemoveAuctionRecord(record)
        remove(self,record)
        for i,r in ipairs(latest) do if r==record then tremove(latest,i);break end end
        u:render(latest)
    end
    u.listing:SetHandler('OnSelectionChanged',function(_,datum)
        u.buy:Disable();if u.bid then u.bid:Disable() end
        if datum then select(datum.record) end
    end)
    u.listing:SetHandler('OnClick',function(row,button)
        if IsAltKeyDown() then
            local selection=u.listing:GetSelection()
            if selection and selection.record==row.record then
                if kind=='owner' or button=='LeftButton' then u.buy:Click() elseif u.bid then u.bid:Click() end
            end
        elseif button=='RightButton' then
            aux.set_tab(1);require('aux.tabs.search').forever_search_item(row.record)
        end
    end)
    return u
end

module 'aux.tabs.auctions'
local aux=require 'aux'
local gui=require 'aux.gui'
local management=require 'aux.forever.management'
local view
function forever_management_update() view:render(auction_records) end
function aux.handle.INIT_UI()
    if not gui.is_forever() then return end
    view=management.build('owner',on_update,find_auction,scan_auctions)
    frame=view.frame;listing=view.listing;status_bar=view.status
    cancel_button=view.buy
end

module 'aux.tabs.bids'
local aux=require 'aux'
local gui=require 'aux.gui'
local management=require 'aux.forever.management'
local view
function forever_management_update() view:render(auction_records) end
function aux.handle.INIT_UI()
    if not gui.is_forever() then return end
    view=management.build('bidder',on_update,find_auction,scan_bids)
    frame=view.frame;listing=view.listing;status_bar=view.status
    buyout_button=view.buy;bid_button=view.bid
end
