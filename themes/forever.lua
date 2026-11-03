module 'aux'

local aux = require 'aux'
local gui = require 'aux.gui'
local L = require('aux.locale').t
local media = require 'aux.forever.media'
local W = require 'aux.forever.widgets'

function M.build_forever()
    local frame = CreateFrame('Frame', 'aux_frame', UIParent)
    M.frame = frame
    tinsert(UISpecialFrames, 'aux_frame')
    gui.set_size(frame, 960, 640)
    frame:SetPoint('CENTER', UIParent, 'CENTER')
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    media.panel(frame, true)
    frame:SetScript('OnShow', function() PlaySound('AuctionWindowOpen') end)
    frame:SetScript('OnHide', function() PlaySound('AuctionWindowClose'); CloseAuctionHouse() end)
    local titlebar = CreateFrame('Frame', nil, frame)
    titlebar:SetPoint('TOPLEFT', 8, -8)
    titlebar:SetPoint('TOPRIGHT', -8, -8)
    titlebar:SetHeight(32)
    media.strip(titlebar,'title-bg','BACKGROUND')
    titlebar:EnableMouse(true)
    titlebar:RegisterForDrag('LeftButton')
    titlebar:SetScript('OnDragStart', function() frame:StartMoving() end)
    titlebar:SetScript('OnDragStop', function() frame:StopMovingOrSizing() end)
    local portrait = titlebar:CreateTexture(nil, 'ARTWORK')
    portrait:SetPoint('TOPLEFT', -2, 7)
    gui.set_size(portrait, 58, 58)
    SetPortraitTexture(portrait, 'player')
    local ring=titlebar:CreateTexture(nil,'OVERLAY')
    ring:SetTexture(media.path('portrait-ring'));gui.set_size(ring,78,78);ring:SetPoint('CENTER',portrait,'CENTER',0,0)
    local title = gui.label(titlebar, 20)
    title:SetPoint('CENTER', titlebar, 'CENTER')
    title:SetTextColor(1, .82, 0)
    local close = media.icon_button(frame,'close',30)
    close:SetPoint('TOPRIGHT', -5, -5)
    close:SetScript('OnClick', function() frame:Hide() end)

    local host = CreateFrame('Frame', nil, frame)
    frame.page_host = host
    host:SetPoint('TOPLEFT', 16, -72)
    host:SetPoint('BOTTOMRIGHT', -16, 48)
    frame.content = CreateFrame('Frame', nil, host)
    frame.content:SetPoint('TOPLEFT', 4, -80)
    frame.content:SetPoint('BOTTOMRIGHT', -4, 35)

    local wallet=CreateFrame('Frame',nil,frame)
    wallet:SetPoint('BOTTOMLEFT',14,12);gui.set_size(wallet,190,25)
    media.strip(wallet,'input-bg','BACKGROUND',128,6)
    local money=W.amount(wallet)
    money:SetPoint('RIGHT',wallet,'RIGHT',-8,0)
    wallet:SetScript('OnEvent',function() money:SetValue(GetMoney()) end)
    wallet:RegisterEvent('PLAYER_MONEY')
    wallet:SetScript('OnShow',function() money:SetValue(GetMoney()) end)
    local menu = gui.button(frame, 13)
    menu:SetPoint('BOTTOMRIGHT', -16, 12)
    menu:SetText('...')
    menu:SetWidth(32)
    menu:SetScript('OnClick', function()
        gui.menu(L'Blizzard UI', function()
            if AuctionFrame:IsVisible() then HideUIPanel(AuctionFrame) else ShowUIPanel(AuctionFrame) end
        end)
    end)

    local main, sub = {}, {}
    local active_management = 3
    local titles = {L'Browse Auctions', L'Post Auctions', L'Auctions', L'Bids'}
    function M.set_tab(id)
        for i, button in ipairs(main) do
            if id and (i == id or i == 3 and id == 4) then button:LockHighlight() else button:UnlockHighlight() end
        end
        for i, button in ipairs(sub) do
            if id == 3 or id == 4 then button:Show() else button:Hide() end
            if id == i + 2 then button:LockHighlight() else button:UnlockHighlight() end
        end
        if id == 3 or id == 4 then active_management = id end
        title:SetText(titles[id] or '')
        on_tab_click(id)
    end
    -- Keep all four logical tabs; the shell only changes their presentation.
    tabs = {create_tab=function() end}
    for i, name in ipairs({L'Buy', L'Sell', L'Auctions'}) do
        local button = media.button(frame,18,'tab')
        gui.set_size(button, 90, 32)
        button:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 26 + (i - 1) * 94, 2)
        button:SetText(name)
        button.id = i
        button:SetScript('OnClick', function() aux.set_tab(this.id == 3 and active_management or this.id) end)
        main[i] = button
    end
    for i, name in ipairs({L'Auctions', L'Bids'}) do
        local button = media.button(frame,14,'tab')
        gui.set_size(button, 90, 24)
        button:SetPoint('TOPLEFT', 78 + (i - 1) * 96, -44)
        button:SetText(name)
        button.id = i + 2
        button:SetScript('OnClick', function() aux.set_tab(this.id) end)
        button:Hide()
        sub[i] = button
    end
    frame:Hide()
end
