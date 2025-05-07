-- Plugin to strip a specific prefix from the request path
-- Based on this: https://github.com/alexashley/kong-plugin-path-prefix
-- Rewritten to support Kong 3+ version

local HEADER_FORWARDED_PREFIX = "X-Forwarded-Prefix"

local StripPrefix = {
  VERSION  = "1.0.0",
  PRIORITY = 800,
}

-- Function to escape hyphens in the path prefix if needed
local function escape_hyphen(conf)
    local path_prefix = conf.path_prefix
    local should_escape = conf.escape

    if should_escape then
        return string.gsub(path_prefix, "%-", "%%%1")
    end

    return path_prefix
end

-- Access phase handler to modify the request path
function StripPrefix:access(plugin_conf)

    -- local service_path = ngx.ctx.service.path or ""
    local full_path = kong.request.get_path()
    -- Escape hyphens in the path prefix if required
    local replace_match = escape_hyphen(plugin_conf)
    local path_without_prefix = full_path

    -- Replace only if full_path starts with replace_match
    if (full_path:find(replace_match) == 1) then
        path_without_prefix = full_path:gsub(replace_match, "", 1)
    end

    -- Set path_without_prefix to '/' if both it and service_path are empty
    -- if path_without_prefix == "" and service_path == "" then
    if path_without_prefix == "" then
        path_without_prefix = "/"
    end

    local new_path = path_without_prefix
    kong.log("Rewriting ", full_path, " to ", path_without_prefix)

    -- Prefix the request with service path if available
    -- if service_path ~= "" then
    --     kong.log("Prefixing request with service path ", service_path)
    --     new_path = service_path .. new_path
    -- end

    -- Add X-Forwarded-Prefix header if required
    if plugin_conf.forwarded_header then
        kong.log("Adding Header: ", HEADER_FORWARDED_PREFIX, plugin_conf.path_prefix)
        kong.service.request.set_header(HEADER_FORWARDED_PREFIX, plugin_conf.path_prefix)
    end

    -- Set the new request path
    kong.service.request.set_path(new_path)
    kong.log("Stripped request path: ", new_path)
    kong.log("New request path: ", kong.request.get_path())
end

return StripPrefix

