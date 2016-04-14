package.path =  '/etc/nginx/lua/upload.lua'

local upload = require 'upload'

local chunk_size = 4096
local form = upload:new(chunk_size)
local file
local filelen=0
form:set_timeout(0)
local filename

function get_filename(res)
	local filename = ngx.re.match(res,'(.+)filename="(.+)"(.*)')
	if filename then
		return filename[2]
	end
end


local i=0
while true do
	local typ, res, err = form:read()
	if not typ then
		ngx.say("failed to read: ", err)
		return
	end
	if typ == "header" then
		if res[1] ~= "Content-Type" then
			filename = get_filename(res[2])
			fullpath = ngx.var.document_root .. ngx.re.match(ngx.var.uri,'(yum)(.*)')[2]
			os.execute("mkdir -p " .. fullpath)
			ngx.say(fullpath)
			if filename then
				i=i+1
				filepath = fullpath .. '/' .. filename
				file = io.open(filepath, "w+")
				if not file then
					ngx.say("failed to openfile ")
					return
				end
			end
		end
	elseif typ == "body" then
		if file then
			filelen = filelen + tonumber(string.len(res))
			file:write(res)
		end
	elseif typ == "part_end" then
		if file then
			file:close()
			file = nil
			ngx.say("file upload success")
		end
	elseif typ == "eof" then
		break
	end
end
if i == 0 then
	ngx.say("please upload at least on file!")
	return
end

