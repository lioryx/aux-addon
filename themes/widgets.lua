module 'aux.forever.widgets'
local gui = require 'aux.gui'
local aux = require 'aux'
local L = require('aux.locale').t
local media = require 'aux.forever.media'

function M.panel(parent)
    local f = CreateFrame('Frame', nil, parent)
    media.panel(f)
    return f
end
function M.text(parent, value, size)
    local t = parent:CreateFontString(nil,'OVERLAY')
    t:SetFont(GameFontNormal:GetFont(), size or 14)
    t:SetTextColor(1,.82,0)
    t:SetJustifyH('LEFT')
    t:SetText(value or '')
    return t
end
function M.button(parent, label, width, click)
    local b = gui.button(parent,14)
    gui.set_size(b,width or 100,26)
    b:SetText(label)
    b:SetScript('OnClick',click)
    return b
end
function M.tab_button(parent,label,width,click)
    local b=media.button(parent,14,'tab')
    gui.set_size(b,width or 100,26);b:SetText(label);b:SetScript('OnClick',click)
    return b
end
function M.icon_button(parent,name,size,click)
    local b=media.icon_button(parent,name,size)
    b:SetScript('OnClick',click)
    return b
end
function M.input(parent,width)
    local e=CreateFrame('EditBox',gui.unique_name(),parent)
    media.input(e)
    e:SetAutoFocus(false)
    gui.set_size(e,width or 90,24)
    e:SetFont(GameFontNormal:GetFont(),14)
    e:SetScript('OnEscapePressed',function() this:ClearFocus() end)
    e:SetScript('OnEditFocusGained',function() this.forever_focused=true end)
    e:SetScript('OnEditFocusLost',function() this.forever_focused=false end)
    return e
end
function M.check(parent,label,callback)
    local b=CreateFrame('CheckButton',gui.unique_name(),parent)
    media.check(b)
    gui.set_size(b,24,24)
    local t=text(b,label,14)
    t:SetPoint('LEFT',b,'RIGHT',3,0)
    b.label=t
    b:SetScript('OnClick',function() callback(this:GetChecked() and true or false) end)
    return b
end
-- Recycled visible rows only; headers and scroll offset survive data refreshes.
function M.list(parent,columns,click)
    local f=CreateFrame('Frame',nil,parent)
    f.rows={}; f.data={}; f.offset=0; f.columns=columns
    local bar=CreateFrame('Slider',gui.unique_name(),f)
    bar:SetOrientation('VERTICAL');bar:SetWidth(16)
    media.scrollbar(bar)
    for i,direction in ipairs({'up','down'}) do
        local delta=i==1 and -3 or 3
        local b=media.icon_button(bar,'arrow-'..direction,18)
        b:SetPoint(i==1 and 'BOTTOM' or 'TOP',bar,i==1 and 'TOP' or 'BOTTOM',0,0)
        b:SetScript('OnClick',function() bar:SetValue(bar:GetValue()+delta) end)
    end
    bar:SetPoint('TOPRIGHT',-3,-44);bar:SetPoint('BOTTOMRIGHT',-3,20)
    bar:SetMinMaxValues(0,0);bar:SetValueStep(1);bar:SetValue(0)
    f.scroll=bar
    f.headers={}
    for i,col in ipairs(columns) do
        local b=CreateFrame('Button',nil,f)
        b:SetHeight(26)
        media.strip(b,'header','BACKGROUND',128,6)
        b.arrow=b:CreateTexture(nil,'OVERLAY');gui.set_size(b.arrow,12,12);b.arrow:SetPoint('RIGHT',-3,0);b.arrow:SetVertexColor(1,.82,.25);b.arrow:Hide()
        local label=text(b,col.name,14);label:SetAllPoints();label:SetJustifyH(col.align or 'LEFT')
        b.text=label;b.column=i
        b:SetScript('OnClick',function() if f.sort then if f.sort_column==this.column then f.sort_reverse=not f.sort_reverse else f.sort_column=this.column;f.sort_reverse=false end;f.sort(this.column) end end)
        f.headers[i]=b
    end
    function f:render()
        local width=math.max(1,self:GetWidth()-28)
        local n=math.max(1,math.floor((self:GetHeight()-30)/23))
        self.offset=math.min(self.offset,math.max(0,getn(self.data)-n))
        bar:SetMinMaxValues(0,math.max(0,getn(self.data)-n))
        if bar:GetValue() ~= self.offset then bar:SetValue(self.offset) end
        local x=4
        for i,col in ipairs(self.columns) do
            local h=self.headers[i];h.text:SetText(col.name)
            if self.sort_column==i then h.arrow:SetTexture(media.path(self.sort_reverse and 'arrow-down' or 'arrow-up'));h.arrow:Show() else h.arrow:Hide() end
            h:ClearAllPoints();h:SetPoint('TOPLEFT',x,0);h:SetWidth(width*col.width)
            x=x+width*col.width
        end
        for i=1,n do
            if not self.rows[i] then
                local row=CreateFrame('Button',nil,self)
                row:RegisterForClicks('LeftButtonUp','RightButtonUp')
                row:SetHeight(23);row.cells={}
                row.icon=row:CreateTexture(nil,'ARTWORK');gui.set_size(row.icon,19,19)
                row.bg=row:CreateTexture(nil,'BACKGROUND');row.bg:SetAllPoints();row.bg:SetTexture(1,1,1,i/2==math.floor(i/2) and .035 or .015)
                row.category_art=media.strip(row,'header','BACKGROUND',128,6);row.category_art:Hide()
                row:SetHighlightTexture(media.path('row-highlight'))
                row:SetScript('OnClick',function() if this.data then click(this.data,arg1,this) end end)
                row:SetScript('OnEnter',function()
                    if this.data and this.data.link then GameTooltip:SetOwner(this,'ANCHOR_RIGHT');GameTooltip:SetHyperlink(this.data.link);GameTooltip:Show() end
                end)
                row:SetScript('OnLeave',function() GameTooltip:Hide() end)
                for j,col in ipairs(self.columns) do
                    local label=text(row,'',14);label:SetTextColor(1,1,1);label:SetJustifyH(col.align or 'LEFT');row.cells[j]=label
                end
                self.rows[i]=row
            end
            local row=self.rows[i];row:ClearAllPoints();row:SetPoint('TOPLEFT',4,-29-(i-1)*23);row:SetWidth(width)
            row.data=self.data[self.offset+i]
            if row.data then
                if row.data.value and not row.data.value.slot then row.category_art:Show() else row.category_art:Hide() end
                row.icon:Hide()
                local x=0
                for j,col in ipairs(self.columns) do
                    local inset=row.data.icon and row.data.icon.column==j and 23 or 0
                    local label=row.cells[j];label:ClearAllPoints();label:SetPoint('LEFT',x+inset,0);label:SetWidth(width*col.width-5-inset);label:SetHeight(23)
                    if inset>0 then row.icon:ClearAllPoints();row.icon:SetPoint('LEFT',x,0);row.icon:SetTexture(row.data.icon.texture);row.icon:Show() end
                    if row.data.value and not row.data.value.subclass then label:SetTextColor(1,.82,0) else label:SetTextColor(.94,.93,.90) end
                    local value=row.data.cells[j]
                    if type(value)=='table' and value.money then
                        label:SetText('')
                        row.money=row.money or {}
                        if not row.money[j] then row.money[j]=amount(row) end
                        row.money[j]:ClearAllPoints();row.money[j]:SetPoint('RIGHT',label,'RIGHT',0,0)
                        row.money[j]:SetValue(value.money);row.money[j]:Show()
                    else
                        label:SetText(value or '')
                        if row.money and row.money[j] then row.money[j]:Hide() end
                    end
                    x=x+width*col.width
                end
                if self.selected and self.selected(row.data) then row:LockHighlight() else row:UnlockHighlight() end
                row:Show()
            else row:Hide() end
        end
        for i=n+1,getn(self.rows) do self.rows[i]:Hide() end
    end
    function f:SetData(data, reset)
        self.data=data or {};if reset then self.offset=0 end
        if self:IsVisible() then self:render() end
    end
    bar:SetScript('OnValueChanged',function() local value=math.floor(this:GetValue());if value~=f.offset then f.offset=value;f:render() end end)
    f:EnableMouseWheel(true)
    f:SetScript('OnMouseWheel',function() bar:SetValue(bar:GetValue()-arg1*3) end)
    f:SetScript('OnShow',function() this:render() end)
    f:SetScript('OnSizeChanged',function() if this:IsVisible() then this:render() end end)
    return f
end
function M.money_input(parent,label,onchange)
    local f=CreateFrame('Frame',nil,parent);gui.set_size(f,300,46)
    local title=text(f,label,14);title:SetPoint('TOPLEFT',0,0);f.label=title
    f.inputs={}
    local units={{10000,'Gold'},{100,'Silver'},{1,'Copper'}}
    for i,u in ipairs(units) do
        local unit_index=i
        local e=input(f,i==1 and 100 or 58);e:SetPoint('TOPLEFT',5+(i==1 and 0 or 122+(i-2)*86),-22)
        e:SetNumeric(true);e:SetMaxLetters(i==1 and 7 or 2)
        local icon=e:CreateTexture(nil,'ARTWORK');gui.set_size(icon,16,16);icon:SetPoint('RIGHT',e,'RIGHT',-5,0)
        e:SetTextInsets(7,24,2,2)
        media.coin(icon,i)
        f.inputs[i]=e
        e:SetScript('OnTextChanged',function() if not f.updating and this.forever_focused then onchange(f:GetAmount()) end end)
        e:SetScript('OnEnterPressed',function() this:ClearFocus() end)
        e:SetScript('OnTabPressed',function() f.inputs[mod(unit_index,3)+1]:SetFocus() end)
    end
    function f:GetAmount() return (tonumber(self.inputs[1]:GetText()) or 0)*10000+(tonumber(self.inputs[2]:GetText()) or 0)*100+(tonumber(self.inputs[3]:GetText()) or 0) end
    function f:SetAmount(amount)
        for _,e in ipairs(self.inputs) do if e.forever_focused then return end end
        amount=math.max(0,math.floor((amount or 0)+.5));self.updating=true
        self.inputs[1]:SetText(math.floor(amount/10000));self.inputs[2]:SetText(math.floor(mod(amount,10000)/100));self.inputs[3]:SetText(mod(amount,100));self.updating=false
    end
    f:SetAmount(0)
    return f
end

-- Bundled three-coin atlas, with pfUI-style two-pixel number/icon spacing.
function M.amount(parent)
    local f=CreateFrame('Frame',nil,parent);f:SetHeight(20);f.parts={}
    for i,unit in ipairs({'Gold','Silver','Copper'}) do
        local t=text(f,'',14);t:SetTextColor(1,1,1)
        local icon=f:CreateTexture(nil,'ARTWORK');gui.set_size(icon,16,16)
        media.coin(icon,i)
        f.parts[i]={text=t,icon=icon}
    end
    function f:SetValue(value)
        value=math.max(0,math.floor(value+.5))
        local amounts={math.floor(value/10000),math.floor(mod(value,10000)/100),mod(value,100)}
        local x=0
        for i,part in ipairs(self.parts) do
            if amounts[i]>0 or i==3 or (i==2 and amounts[1]>0) then
                part.text:SetText(amounts[i]);part.text:ClearAllPoints();part.text:SetPoint('LEFT',x,0);part.text:Show()
                local width=part.text:GetStringWidth()
                part.icon:ClearAllPoints();part.icon:SetPoint('LEFT',x+width+2,0);part.icon:Show()
                x=x+width+22
            else part.text:Hide();part.icon:Hide() end
        end
        self:SetWidth(math.max(x,1))
    end
    return f
end
