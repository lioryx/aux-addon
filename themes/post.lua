module 'aux.tabs.post'
local aux=require 'aux'
local gui=require 'aux.gui'
local W=require 'aux.forever.widgets'
local info=require 'aux.util.info'
local money=require 'aux.util.money'
local history=require 'aux.core.history'
local listing_util=require 'aux.gui.listing'
local item_listing=require 'aux.gui.item_listing'
local search=require 'aux.tabs.search'
local L=require('aux.locale').t
local comparisons={}
local compare_table, total_label, auto_label, history_label, one_price
local comparison_sort, comparison_reverse=2,false

function forever_post_records_reset(key) comparisons[key]={} end
function forever_post_record(key,record)
    comparisons[key]=comparisons[key] or {}
    tinsert(comparisons[key],record)
    refresh=true
end
function forever_post_render()
    if not compare_table then return end
    local rows={}
    if selected_item then
        for _,r in ipairs(comparisons[selected_item.key] or {}) do
            tinsert(rows,{record=r,link=r.link,cells={{money=r.unit_blizzard_bid},r.buyout_price>0 and {money=r.unit_buyout_price} or L'Bid only',r.count,r.level}})
        end
        table.sort(rows,function(a,b)
            local x,y=a.record,b.record
            local av,bv
            if comparison_sort==1 then av,bv=x.unit_blizzard_bid,y.unit_blizzard_bid
            elseif comparison_sort==3 then av,bv=x.count,y.count
            elseif comparison_sort==4 then av,bv=x.level,y.level
            else av,bv=x.buyout_price>0 and x.unit_buyout_price or aux.huge,y.buyout_price>0 and y.unit_buyout_price or aux.huge end
            if av==bv then return x.search_signature<y.search_signature end
            if comparison_reverse then return av>bv end
            return av<bv
        end)
        local stack=stack_size_slider:GetValue()
        local count=stack_count_slider:GetValue()
        local buyout=get_unit_buyout_price()
        local starting=forever_buyout_only and buyout or get_unit_start_price()
        local automatic=not forever_buyout_only and starting==0
        total_label:SetText(automatic and L'Total: determined by automatic pricing' or L'Total: '..money.to_string(aux.round((buyout>0 and buyout or starting)*stack)*count))
        auto_label:SetText(automatic and L'Starting price 0 enables automatic pricing; the final buyout may change.' or '')
        local h=history.value(selected_item.key)
        history_label:SetText(L'Historical value: '..(h and money.to_string(h) or L'Unknown'))
        unit_start_price_input:SetAmount(get_unit_start_price());unit_buyout_price_input:SetAmount(buyout)
        unit_start_price_input.label:SetText(selected_item.max_charges and L'Starting price per charge' or L'Unit Starting Price')
        unit_buyout_price_input.label:SetText(selected_item.max_charges and L'Buyout price per charge' or L'Unit Buyout Price')
        if forever_buyout_only then unit_start_price_input:Hide();start_price_percentage:Hide() else unit_start_price_input:Show();start_price_percentage:Show() end
    else total_label:SetText('');auto_label:SetText('');history_label:SetText('') end
    compare_table:SetData(rows)
end
function aux.handle.INIT_UI()
    if not gui.is_forever() then return end
    frame=CreateFrame('Frame',nil,gui.page_parent());frame:SetAllPoints();frame:SetScript('OnUpdate',on_update);frame:Hide()
    frame.content=CreateFrame('Frame',nil,frame);frame.content:SetAllPoints()
    frame.parameters=W.panel(frame.content);frame.parameters:SetPoint('TOPLEFT',0,-36);frame.parameters:SetPoint('BOTTOMLEFT',0,0);frame.parameters:SetWidth(413)
    local compare_panel=W.panel(frame.content);compare_panel:SetPoint('TOPLEFT',421,-36);compare_panel:SetPoint('BOTTOMRIGHT',0,0)
    compare_table=W.list(compare_panel,{{name=L'Bid / unit',width=.34},{name=L'Buyout / unit',width=.34},{name=L'Quantity',width=.16},{name=L'Lvl',width=.16}},function(row,button)
        if not selected_item then return end
        if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then ChatFrameEditBox:Insert(row.record.link);return end
        if IsControlKeyDown() then DressUpItemLink(row.record.link);return end
        unit_start_price_input:ClearFocus();unit_buyout_price_input:ClearFocus()
        local r=row.record
        local record={unit_price=button=='RightButton' and r.unit_blizzard_bid or r.unit_buyout_price,stack_size=r.aux_quantity,own=info.is_player(r.owner)}
        set_bid_selection();set_buyout_selection()
        if button=='RightButton' or r.buyout_price==0 then record.unit_price=r.unit_blizzard_bid;set_bid_selection(record) else set_buyout_selection(record) end
        refresh=true
    end);compare_table:SetPoint('TOPLEFT',5,-4);compare_table:SetPoint('BOTTOMRIGHT',-5,35)
    compare_table.sort_column=2
    compare_table.sort=function(col) if comparison_sort==col then comparison_reverse=not comparison_reverse else comparison_sort=col;comparison_reverse=false end;forever_post_render() end
    history_label=W.text(compare_panel,'',13);history_label:SetPoint('BOTTOMLEFT',12,12)
    frame.inventory=W.panel(frame);frame.inventory:SetFrameLevel(frame:GetFrameLevel()+20);frame.inventory:SetPoint('TOPLEFT',0,-36);frame.inventory:SetPoint('BOTTOMLEFT',0,0);frame.inventory:SetWidth(413)
    show_hidden_checkbox=W.check(frame.inventory,L'Show hidden items',function() refresh=true end);show_hidden_checkbox:SetPoint('TOPLEFT',12,-12)
    local inventory_close=W.button(frame.inventory,L'Close',80,function() frame.inventory:Hide() end);inventory_close:SetPoint('TOPRIGHT',-8,-10)
    local inv=CreateFrame('Frame',nil,frame.inventory);inv:SetPoint('TOPLEFT',5,-48);inv:SetPoint('BOTTOMRIGHT',-5,5)
    inventory_listing=item_listing.new(inv,function()
        if arg1=='LeftButton' then update_item(this.item_record);frame.inventory:Hide()
        elseif arg1=='RightButton' then aux.set_tab(1);search.forever_search_item(this.item_record) end
    end,function(r) return r==selected_item end)
    frame.inventory:Hide()
    local inventory_button=W.tab_button(frame,L'Inventory',130,function() if frame.inventory:IsShown() then frame.inventory:Hide() else frame.inventory:Show();update_inventory_listing() end end);inventory_button:SetPoint('TOPLEFT',0,0)
    refresh_button=W.icon_button(frame,'refresh',28,refresh_button_click);refresh_button:SetPoint('TOPRIGHT',0,0)
    status_bar=gui.status_bar(frame);status_bar:SetPoint('LEFT',inventory_button,'RIGHT',12,0);gui.set_size(status_bar,380,24)
    item=gui.item(frame.parameters);item:SetPoint('TOPLEFT',14,-12);item:SetWidth(380)
    item.button:SetScript('OnEnter',function() if selected_item then info.set_tooltip(selected_item.itemstring,this,'ANCHOR_RIGHT') end end)
    item.button:SetScript('OnLeave',function() GameTooltip:Hide() end)
    one_price=W.check(frame.parameters,L'Buyout only',function(enabled) forever_buyout_only=enabled;aux.account_data.forever_buyout_only=enabled;refresh=true end)
    one_price:SetPoint('TOPLEFT',12,-65)
    local function price_input(label,start)
        local input=W.money_input(frame.parameters,label,function(amount)
            if not selected_item then return end
            set_bid_selection();set_buyout_selection()
            if start then set_unit_start_price(amount) else set_unit_buyout_price(amount) end
            refresh=true
        end)
        function input:SetText(value) self:SetAmount(money.from_string(value) or 0) end
        function input:SetFocus() self.inputs[1]:SetFocus() end
        function input:ClearFocus() for _,e in ipairs(self.inputs) do e:ClearFocus() end end
        return input
    end
    unit_start_price_input=price_input(L'Unit Starting Price',true);unit_start_price_input:SetPoint('TOPLEFT',18,-100)
    unit_buyout_price_input=price_input(L'Unit Buyout Price',false);unit_buyout_price_input:SetPoint('TOPLEFT',18,-158)
    start_price_percentage=W.text(unit_start_price_input,'',12);start_price_percentage:SetPoint('TOPRIGHT',80,-24)
    buyout_price_percentage=W.text(unit_buyout_price_input,'',12);buyout_price_percentage:SetPoint('TOPRIGHT',80,-24)
    stack_size_slider=gui.slider(frame.parameters);stack_size_slider:SetPoint('TOPLEFT',18,-230);stack_size_slider:SetWidth(160);stack_size_slider:SetValueStep(1);stack_size_slider.label:SetText(L'Stack Size')
    stack_size_slider:SetScript('OnValueChanged',function() quantity_update(true) end)
    stack_size_slider:SetScript('OnMouseUp',function() if selected_item and aux.account_data.post_stack then local s=read_settings();s.stack_size=stack_size_slider:GetValue();write_settings(s) end end)
    stack_size_slider.editbox.change=function()
        stack_size_slider:SetValue(this:GetNumber());quantity_update(true)
        if selected_item and this.focused and aux.account_data.post_stack then local s=read_settings();s.stack_size=stack_size_slider:GetValue();write_settings(s) end
    end
    stack_size_slider.editbox:SetNumeric(true)
    stack_count_slider=gui.slider(frame.parameters);stack_count_slider:SetPoint('TOPLEFT',220,-230);stack_count_slider:SetWidth(160);stack_count_slider:SetValueStep(1);stack_count_slider.label:SetText(L'Stack Count')
    stack_count_slider:SetScript('OnValueChanged',function() quantity_update() end)
    stack_count_slider.editbox.change=function() stack_count_slider:SetValue(this:GetNumber());quantity_update() end
    stack_count_slider.editbox:SetNumeric(true)
    duration_dropdown=gui.dropdown(frame.parameters);duration_dropdown:SetPoint('TOPLEFT',18,-280);duration_dropdown:SetWidth(140)
    local duration_label=W.text(frame.parameters,L'Duration');duration_label:SetPoint('BOTTOMLEFT',duration_dropdown,'TOPLEFT',0,2)
    UIDropDownMenu_Initialize(duration_dropdown,initialize_duration_dropdown)
    duration_dropdown:SetScript('OnShow',function() UIDropDownMenu_Initialize(this,initialize_duration_dropdown) end)
    hide_checkbox=W.check(frame.parameters,L'Hide this item',function(enabled) if selected_item then local s=read_settings();s.hidden=enabled;write_settings(s);refresh=true end end);hide_checkbox:SetPoint('TOPLEFT',220,-280)
    deposit=W.text(frame.parameters,'',14);deposit:SetPoint('TOPLEFT',18,-325)
    vendor_price_label=W.text(frame.parameters,'',13);vendor_price_label:SetPoint('TOPLEFT',18,-350)
    total_label=W.text(frame.parameters,'',14);total_label:SetPoint('TOPLEFT',18,-376)
    auto_label=W.text(frame.parameters,'',12);auto_label:SetPoint('TOPLEFT',18,-400);auto_label:SetWidth(375)
    post_button=W.button(frame.parameters,L'Create Auction',250,post_auctions);post_button:SetPoint('BOTTOM',0,12)
    -- The original price tables remain real, accessible advanced views.
    local advanced=W.panel(frame);advanced:SetPoint('TOPLEFT',421,-36);advanced:SetPoint('BOTTOMRIGHT',0,0);advanced:SetFrameLevel(frame:GetFrameLevel()+10)
    frame.bid_listing=W.panel(advanced);frame.bid_listing:SetPoint('TOPLEFT',4,-5);frame.bid_listing:SetPoint('TOPRIGHT',-4,-5);frame.bid_listing:SetHeight(215)
    frame.buyout_listing=W.panel(advanced);frame.buyout_listing:SetPoint('TOPLEFT',frame.bid_listing,'BOTTOMLEFT',0,-5);frame.buyout_listing:SetPoint('BOTTOMRIGHT',-4,5)
    bid_listing=listing_util.new(frame.bid_listing);buyout_listing=listing_util.new(frame.buyout_listing)
    for _,pair in ipairs({{bid_listing,true},{buyout_listing,false}}) do
        local list,is_bid=pair[1],pair[2]
        list:SetColInfo{{name=L'Auctions',width=.12},{name=L'Time Left',width=.14},{name=L'Stack Size',width=.14},{name=is_bid and L'Bid / unit' or L'Buyout / unit',width=.4},{name=L'% Hist. Value',width=.2}}
        list:SetHandler('OnClick',function(_,row) if selected_item then if is_bid then set_bid_selection(row.record) else set_buyout_selection(row.record) end;refresh=true end end)
        list:SetHandler('OnDoubleClick',function(_,row) stack_size_slider:SetValue(row.record.stack_size);refresh=true end)
    end
    advanced:Hide()
    local adv=W.tab_button(frame,L'Advanced',100,function() if advanced:IsShown() then advanced:Hide() else advanced:Show() end end);adv:SetPoint('RIGHT',refresh_button,'LEFT',-8,0)
end
function aux.handle.LOAD()
    if not gui.is_forever() then return end
    forever_buyout_only=aux.account_data.forever_buyout_only and true or false
    one_price:SetChecked(forever_buyout_only)
end
