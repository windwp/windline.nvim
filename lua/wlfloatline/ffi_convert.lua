-- credit to @justinmk
-- https://github.com/justinmk

local ffi = require('ffi')

local M = {}
ffi.cdef([[
typedef unsigned char char_u;
typedef struct window_S win_T;
extern win_T    *curwin;
typedef struct {
  char_u      *start;
  int userhl;
} stl_hlrec_t;
typedef struct {
} StlClickDefinition;
typedef struct {
  StlClickDefinition def;
  const char *start;
} StlClickRecord;
int build_stl_str_hl(
    win_T *wp,
    char_u *out,
    size_t outlen,
    char_u *fmt,
    int use_sandbox,
    char_u fillchar,
    int maxwidth,
    stl_hlrec_t **hltab,
    StlClickRecord **tabtab
);
]])

local function gen_stl(stl_fmt)
    local stlbuf = ffi.new('char_u [?]', 256)
    local fmt = ffi.cast('char_u *', stl_fmt)
    local fillchar = ffi.cast('char_u', 0x20)
    local hltab = ffi.new('stl_hlrec_t *[1]', ffi.new('stl_hlrec_t *'))
    ffi.C.build_stl_str_hl(
        ffi.C.curwin,
        stlbuf,
        256,
        fmt,
        0,
        fillchar,
        vim.go.columns,
        hltab,
        nil
    )
    return stlbuf, hltab
end

local function process_hlrec(hltab, stlbuf)
    local len = #ffi.string(stlbuf)
    local hltab_data = hltab[0]
    local result = {}
    local n = 0
    while hltab_data[n].start ~= nil do
        local hl_pos = { hl = vim.fn.synIDattr(-1 * hltab_data[n].userhl, 'name') }
        if n == 0 then
            hl_pos.start = hltab_data[n].start - stlbuf
        else
            hl_pos.start = result[#result].start + result[#result].len
        end
        if hltab_data[n + 1].start ~= nil then
            hl_pos.len = hltab_data[n + 1].start - hltab_data[n].start
        else
            hl_pos.len = (stlbuf + len) - hltab_data[n].start
        end
        table.insert(result, hl_pos)
        n = n + 1
    end
    return result
end

M.get_stl_format = function(stl_expr)
    local stl_buf, hltab = gen_stl(stl_expr)
    local hl_list = process_hlrec(hltab, stl_buf)
    return ffi.string(stl_buf), hl_list
end

M.get_stl_string = function(stl_expr)
    local stl_buf = gen_stl(stl_expr)
    return ffi.string(stl_buf)
end

return M
