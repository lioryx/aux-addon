module 'aux.forever.media'

local ROOT = [[Interface\AddOns\aux-addon\textures\forever\]]
function M.path(name) return ROOT .. name end

-- Three slices keep the metal caps crisp when controls change width.
function M.strip(parent, name, layer, source_width, cap)
    source_width, cap = source_width or 256, cap or 8
    local pieces={}
    for i=1,3 do
        local t=parent:CreateTexture(nil,layer or 'BACKGROUND')
        t:SetTexture(path(name))
        if i==1 then
            t:SetWidth(cap);t:SetPoint('TOPLEFT',0,0);t:SetPoint('BOTTOMLEFT',0,0)
            t:SetTexCoord(0,cap/source_width,0,1)
        elseif i==3 then
            t:SetWidth(cap);t:SetPoint('TOPRIGHT',0,0);t:SetPoint('BOTTOMRIGHT',0,0)
            t:SetTexCoord(1-cap/source_width,1,0,1)
        else
            t:SetPoint('TOPLEFT',cap,0);t:SetPoint('BOTTOMRIGHT',-cap,0)
            t:SetTexCoord(cap/source_width,1-cap/source_width,0,1)
        end
        pieces[i]=t
    end
    function pieces:Show() for i=1,3 do self[i]:Show() end end
    function pieces:Hide() for i=1,3 do self[i]:Hide() end end
    return pieces
end
function M.panel(frame, window)
    frame:SetBackdrop({bgFile=path(window and 'window-bg' or 'panel-bg'),edgeFile=path(window and 'window-edge' or 'panel-edge'),tile=true,tileSize=256,edgeSize=window and 16 or 8,insets={left=5,right=5,top=5,bottom=5}})
    frame:SetBackdropColor(1,1,1,1);frame:SetBackdropBorderColor(1,1,1,1)
end
function M.input(frame)
    frame:SetBackdrop(nil)
    frame.forever_input_art=strip(frame,'input-bg','BACKGROUND',128,6)
    frame:SetTextInsets(8,8,2,2)
end
function M.check(button)
    button:SetNormalTexture(path('check-off'));button:SetPushedTexture(path('check-off'))
    button:SetCheckedTexture(path('check-on'));button:SetDisabledCheckedTexture(path('check-on'))
    button:SetHighlightTexture(path('row-highlight'))
    button:SetWidth(24);button:SetHeight(24)
end
function M.button(parent, size, kind)
    local b=CreateFrame('Button',nil,parent)
    b:SetWidth(100);b:SetHeight(26)
    local is_tab=kind=='tab'
    b.normal_art=strip(b,is_tab and 'tab-normal' or 'button-normal','BACKGROUND',is_tab and 128 or 256)
    b.pressed_art=strip(b,is_tab and 'tab-selected' or 'button-pressed','BORDER',is_tab and 128 or 256);b.pressed_art:Hide()
    b.disabled_art=strip(b,'button-disabled','BORDER');b.disabled_art:Hide()
    if is_tab then b.selected_art=strip(b,'tab-selected','ARTWORK',128);b.selected_art:Hide() end
    b:SetHighlightTexture(path('row-highlight'))
    local t=b:CreateFontString(nil,'OVERLAY')
    t:SetFont(GameFontNormal:GetFont(),size or 14);t:SetTextColor(1,.82,0)
    t:SetPoint('TOPLEFT',5,-2);t:SetPoint('BOTTOMRIGHT',-5,2);t:SetJustifyH('CENTER')
    b:SetFontString(t)
    local enable,disable,lock,unlock=b.Enable,b.Disable,b.LockHighlight,b.UnlockHighlight
    function b:Enable() enable(self);self.disabled_art:Hide();t:SetTextColor(1,.82,0) end
    function b:Disable() disable(self);self.pressed_art:Hide();self.disabled_art:Show();t:SetTextColor(.46,.44,.40) end
    function b:LockHighlight() lock(self);if self.selected_art then self.selected_art:Show();t:SetTextColor(1,1,1) end end
    function b:UnlockHighlight() unlock(self);if self.selected_art then self.selected_art:Hide();t:SetTextColor(1,.82,0) end end
    b:SetScript('OnMouseDown',function() if this:IsEnabled()==1 then this.pressed_art:Show() end end)
    b:SetScript('OnMouseUp',function() this.pressed_art:Hide() end)
    b:SetScript('OnHide',function() this.pressed_art:Hide() end)
    return b
end
function M.set_icon(button,name)
    button:SetNormalTexture(path(name));button:SetPushedTexture(path(name))
    button:GetPushedTexture():SetVertexColor(.65,.65,.65)
end
function M.icon_button(parent,name,size)
    local b=CreateFrame('Button',nil,parent)
    b:SetWidth(size or 26);b:SetHeight(size or 26)
    set_icon(b,name)
    b:SetHighlightTexture(path('row-highlight'))
    return b
end
function M.coin(texture,index)
    texture:SetTexture(path('coins'))
    texture:SetTexCoord((index-1)/4,index/4,0,1)
end
function M.scrollbar(bar,up,down)
    panel(bar)
    bar:SetWidth(14);bar:SetThumbTexture(path('scroll-thumb'))
    local thumb=bar:GetThumbTexture();thumb:SetWidth(12);thumb:SetHeight(36)
    if up then
        set_icon(up,'arrow-up');up:SetDisabledTexture(path('arrow-up'));up:GetDisabledTexture():SetVertexColor(.35,.35,.35)
        up:SetHighlightTexture(path('row-highlight'));up:Show()
    end
    if down then
        set_icon(down,'arrow-down');down:SetDisabledTexture(path('arrow-down'));down:GetDisabledTexture():SetVertexColor(.35,.35,.35)
        down:SetHighlightTexture(path('row-highlight'));down:Show()
    end
end
-- Only the aux-owned opening of the shared dropdown is skinned. Restore on hide
-- so another addon retains its own menu appearance.
local popup_overlays = {}
function M.popup()
    for level=1,2 do
        local menu=_G['DropDownList'..level]
        if menu and menu:IsShown() and not menu.forever_restore then
            local restores={}
            local updates={}
            local function backdrop(frame)
                if not frame then return end
                local old=frame:GetBackdrop()
                local r,g,b,a=frame:GetBackdropColor()
                local br,bg,bb,ba=frame:GetBackdropBorderColor()
                tinsert(restores,function() frame:SetBackdrop(old);frame:SetBackdropColor(r,g,b,a);frame:SetBackdropBorderColor(br,bg,bb,ba) end)
                panel(frame)
            end
            local function texture(tex,asset,owner,layer)
                if not tex or not tex.SetTexture or not tex.SetAlpha or not tex.IsShown then return end
                -- The 1.12 client need not expose Texture:GetTexture(). Leave
                -- its path and UVs untouched, and temporarily cover it instead.
                local alpha=tex.GetAlpha and tex:GetAlpha() or 1
                local overlay=popup_overlays[tex]
                if not overlay then
                    overlay=(owner or menu):CreateTexture(nil,layer or 'ARTWORK')
                    popup_overlays[tex]=overlay
                end
                overlay:ClearAllPoints();overlay:SetAllPoints(tex)
                overlay:SetTexture(path(asset));overlay:SetTexCoord(0,1,0,1)
                overlay:SetAlpha(alpha)
                tex:SetAlpha(0)
                local function update()
                    if tex:IsShown() then overlay:Show() else overlay:Hide() end
                end
                update()
                tinsert(updates,update)
                tinsert(restores,function() overlay:Hide();tex:SetAlpha(alpha) end)
            end
            backdrop(_G[menu:GetName()..'Backdrop'])
            backdrop(_G[menu:GetName()..'MenuBackdrop'])
            for i=1,UIDROPDOWNMENU_MAXBUTTONS or 32 do
                local prefix=menu:GetName()..'Button'..i
                local owner=_G[prefix]
                texture(_G[prefix..'Check'],'check-on',owner)
                texture(_G[prefix..'UnCheck'],'check-off',owner)
                texture(_G[prefix..'ExpandArrow'],'arrow-right',owner)
                texture(_G[prefix..'Highlight'],'row-highlight',owner,'HIGHLIGHT')
            end
            local old_hide=menu:GetScript('OnHide')
            local old_update=menu:GetScript('OnUpdate')
            menu.forever_restore=true
            menu:SetScript('OnUpdate',function()
                if old_update then old_update() end
                if not menu:IsShown() then return end
                for _,update in ipairs(updates) do update() end
            end)
            menu:SetScript('OnHide',function()
                for _,restore in ipairs(restores) do restore() end
                menu.forever_restore=nil
                menu:SetScript('OnUpdate',old_update);menu:SetScript('OnHide',old_hide)
                if old_hide then old_hide() end
            end)
        end
    end
end
