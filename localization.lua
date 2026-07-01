BINDING_HEADER_AUX = "aux";

local L = require('aux.locale').t

-- Bindings.xml 中的 <Binding name="Aux Post"> 生成 BINDING_NAME_AUXPOST，此处本地化其显示名。
BINDING_NAME_AUXPOST = L'Aux Post'

local post = require 'aux.tabs.post'

function post_auctions_bind()
	post.post_auctions_bind()
end