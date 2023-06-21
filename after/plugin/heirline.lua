local conditions = require "heirline.conditions"
local utils = require "heirline.utils"
-- local constructors = require("heirline.constructors")

local function setup_colors()
    return {
        bright_bg = utils.get_highlight("Folded").fg,
        red = utils.get_highlight("DiagnosticError").fg,
        dark_red = utils.get_highlight("DiffDelete").fg,
        green = utils.get_highlight("String").fg,
        blue = utils.get_highlight("Function").fg,
        gray = utils.get_highlight("NonText").fg,
        orange = utils.get_highlight("Constant").fg,
        purple = utils.get_highlight("Statement").fg,
        cyan = utils.get_highlight("Special").fg,
        diag_warn = utils.get_highlight("DiagnosticWarn").fg,
        diag_error = utils.get_highlight("DiagnosticError").fg,
        diag_hint = utils.get_highlight("DiagnosticHint").fg,
        diag_info = utils.get_highlight("DiagnosticInfo").fg,
        git_del = utils.get_highlight("DiffDelete").fg,
        git_add = utils.get_highlight("DiffAdd").fg,
        git_change = utils.get_highlight("DiffChange").fg,
    }
end

require("heirline").load_colors(setup_colors())

local ViMode = {
    init = function(self)
        self.mode = vim.fn.mode(1)
    end,
    static = {
        mode_names = {
            n = "N",
            no = "N?",
            nov = "N?",
            noV = "N?",
            ["no\22"] = "N?",
            niI = "Ni",
            niR = "Nr",
            niV = "Nv",
            nt = "Nt",
            v = "V",
            vs = "Vs",
            V = "V_",
            Vs = "Vs",
            ["\22"] = "^V",
            ["\22s"] = "^V",
            s = "S",
            S = "S_",
            ["\19"] = "^S",
            i = "I",
            ic = "Ic",
            ix = "Ix",
            R = "R",
            Rc = "Rc",
            Rx = "Rx",
            Rv = "Rv",
            Rvc = "Rv",
            Rvx = "Rv",
            c = "C",
            cv = "Ex",
            r = "...",
            rm = "M",
            ["r?"] = "?",
            ["!"] = "!",
            t = "T",
        },
    },
    provider = function(self)
        return " %2(" .. self.mode_names[self.mode] .. "%)"
    end,
    hl = function(self)
        local color = self:mode_color()
        return { fg = color, bold = true }
    end,
    -- update = {
    --     "ModeChanged",
    --     callback = function()
    --         vim.cmd("redrawstatus")
    --     end,
    -- },
}


local FileNameBlock = {
    -- let's first set up some attributes needed by this component and it's children
    init = function(self)
        self.filename = vim.api.nvim_buf_get_name(0)
    end,
}
-- We can now define some children separately and add them later

local FileIcon = {
    init = function(self)
        local filename = self.filename
        local extension = vim.fn.fnamemodify(filename, ":e")
        self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
    end,
    provider = function(self)
        return self.icon and (self.icon .. " ")
    end,
    hl = function(self)
        return { fg = self.icon_color }
    end
}

local FileName = {
    provider = function(self)
        -- first, trim the pattern relative to the current directory. For other
        -- options, see :h filename-modifers
        local filename = vim.fn.fnamemodify(self.filename, ":.")
        if filename == "" then return "[No Name]" end
        -- now, if the filename would occupy more than 1/4th of the available
        -- space, we trim the file path to its initials
        -- See Flexible Components section below for dynamic truncation
        if not conditions.width_percent_below(#filename, 0.25) then
            filename = vim.fn.pathshorten(filename)
        end
        return filename
    end,
    hl = { fg = utils.get_highlight("Directory").fg },
}

local FileFlags = {
    {
        condition = function()
            return vim.bo.modified
        end,
        provider = "[+]",
        hl = { fg = "green" },
    },
    {
        condition = function()
            return not vim.bo.modifiable or vim.bo.readonly
        end,
        provider = "",
        hl = { fg = "orange" },
    },
}

-- Now, let's say that we want the filename color to change if the buffer is
-- modified. Of course, we could do that directly using the FileName.hl field,
-- but we'll see how easy it is to alter existing components using a "modifier"
-- component

local FileNameModifer = {
    hl = function()
        if vim.bo.modified then
            -- use `force` because we need to override the child's hl foreground
            return { fg = "cyan", bold = true, force = true }
        end
    end,
}

-- let's add the children to our FileNameBlock component
FileNameBlock = utils.insert(FileNameBlock,
    FileIcon,
    utils.insert(FileNameModifer, FileName), -- a new table where FileName is a child of FileNameModifier
    FileFlags,
    { provider = '%<' }                      -- this means that the statusline is cut here when there's not enough space
)
local FileType = {
    provider = function()
        return string.upper(vim.bo.filetype)
    end,
    hl = "Type",
}

local FileEncoding = {
    provider = function()
        local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc -- :h 'enc'
        return enc ~= "utf-8" and enc:upper()
    end,
}

local FileFormat = {
    provider = function()
        local fmt = vim.bo.fileformat
        return fmt ~= "unix" and fmt:upper()
    end,
}

local FileSize = {
    provider = function()
        -- stackoverflow, compute human readable file size
        local suffix = { "b", "k", "M", "G", "T", "P", "E" }
        local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
        fsize = (fsize < 0 and 0) or fsize
        if fsize <= 0 then
            return "0" .. suffix[1]
        end
        local i = math.floor((math.log(fsize) / math.log(1024)))
        return string.format("%.2g%s", fsize / math.pow(1024, i), suffix[i])
    end,
}

local FileLastModified = {
    provider = function()
        local ftime = vim.fn.getftime(vim.api.nvim_buf_get_name(0))
        return (ftime > 0) and os.date("%c", ftime)
    end,
}

local Ruler = {
    -- %l = current line number
    -- %L = number of lines in the buffer
    -- %c = column number
    -- %P = percentage through file of displayed window
    provider = "%7(%l/%3L%):%2c %P",
}

local ScrollBar = {
    static = {
        sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" },
    },
    provider = function(self)
        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_line_count(0)
        local i = math.floor(curr_line / lines * (#self.sbar - 1)) + 1
        return string.rep(self.sbar[i], 2)
    end,
    hl = { fg = "blue", bg = "bright_bg" },
}

local LSPActive = {
    condition = conditions.lsp_attached,
    update = { "LspAttach", "LspDetach" },
    provider = " [LSP]",
    -- Or complicate things a bit and get the servers names
    -- provider  = function(self)
    --     local names = {}
    --     for i, server in ipairs(vim.lsp.buf_get_clients(0)) do
    --         table.insert(names, server.name)
    --     end
    --     return " [" .. table.concat(names, " ") .. "]"
    -- end,
    hl = { fg = "green", bold = true },
    on_click = {
        name = "heirline_LSP",
        callback = function()
            vim.defer_fn(function()
                vim.cmd "LspInfo"
            end, 100)
        end,
    },
}

local Git = {
    condition = conditions.is_git_repo,
    init = function(self)
        self.status_dict = vim.b.gitsigns_status_dict
        self.has_changes = self.status_dict.added ~= 0
            or self.status_dict.removed ~= 0
            or self.status_dict.changed ~= 0
    end,
    on_click = {
        callback = function(self, minwid, nclicks, button)
            vim.defer_fn(function()
                vim.cmd "Lazygit %:p:h"
            end, 100)
        end,
        name = "heirline_git",
        update = false,
    },
    hl = { fg = "orange" },
    {
        provider = function(self)
            return " " .. self.status_dict.head
        end,
        hl = { bold = true },
    },
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = "(",
    },
    {
        provider = function(self)
            local count = self.status_dict.added or 0
            return count > 0 and ("+" .. count)
        end,
        hl = "DiffAdd",
    },
    {
        provider = function(self)
            local count = self.status_dict.removed or 0
            return count > 0 and ("-" .. count)
        end,
        hl = "DiffDelete",
    },
    {
        provider = function(self)
            local count = self.status_dict.changed or 0
            return count > 0 and ("~" .. count)
        end,
        hl = "DiffChange",
    },
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = ")",
    },
}

local WorkDir = {
    provider = function(self)
        self.icon = (vim.fn.haslocaldir(0) == 1 and "l" or "g") .. " " .. " "
        local cwd = vim.fn.getcwd(0)
        self.cwd = vim.fn.fnamemodify(cwd, ":~")
        if not conditions.width_percent_below(#self.cwd, 0.27) then
            self.cwd = vim.fn.pathshorten(self.cwd)
        end
    end,
    hl = { fg = "blue", bold = true },
    on_click = {
        callback = function()
            vim.cmd "NvimTreeToggle"
        end,
        name = "heirline_workdir",
    },
}

local HelpFilename = {
    condition = function()
        return vim.bo.filetype == "help"
    end,
    provider = function()
        local filename = vim.api.nvim_buf_get_name(0)
        return vim.fn.fnamemodify(filename, ":t")
    end,
    hl = "Directory",
}

local TerminalName = {
    -- icon = ' ', -- 
    {
        provider = function()
            local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
            return " " .. tname
        end,
        hl = { fg = "blue", bold = true },
    },
    { provider = " - " },
    {
        provider = function()
            return vim.b.term_title
        end,
    },
    {
        provider = function()
            local id = require("terminal"):current_term_index()
            return " " .. (id or "Exited")
        end,
        hl = { bold = true, fg = "blue" },
    },
}

local Spell = {
    condition = function()
        return vim.wo.spell
    end,
    provider = "SPELL ",
    hl = { bold = true, fg = "orange" },
}

ViMode = utils.surround({ "", "" }, "bright_bg", { ViMode })

local Align = { provider = "%=" }
local Space = { provider = " " }

local DefaultStatusline = {
    ViMode,
    Space,
    Spell,
    WorkDir,
    FileNameBlock,
    { provider = "%<" },
    Space,
    Git,
    Space,
    Align,
    LSPActive,
    Space,
    -- UltTest,
    Space,
    FileType,
    Space,
    Ruler,
    Space,
    ScrollBar,
}

local InactiveStatusline = {
    condition = function()
        return not conditions.is_active()
    end,
    { hl = { fg = "gray", force = true }, WorkDir },
    FileNameBlock,
    { provider = "%<" },
    Align,
}

local SpecialStatusline = {
    condition = function()
        return conditions.buffer_matches {
            buftype = { "nofile", "prompt", "help", "quickfix" },
            filetype = { "^git.*", "fugitive" },
        }
    end,
    FileType,
    { provider = "%q" },
    Space,
    HelpFilename,
    Align,
}

local GitStatusline = {
    condition = function()
        return conditions.buffer_matches {
            filetype = { "^git.*", "fugitive" },
        }
    end,
    FileType,
    Space,
    {
        provider = function()
            return vim.fn.FugitiveStatusline()
        end,
    },
    Space,
    Align,
}

local StatusLines = {
    hl = function()
        if conditions.is_active() then
            return "StatusLine"
        else
            return "StatusLineNC"
        end
    end,
    static = {
        mode_colors = {
            n = "red",
            i = "green",
            v = "cyan",
            V = "cyan",
            ["\22"] = "cyan", -- this is an actual ^V, type <C-v><C-v> in insert mode
            c = "orange",
            s = "purple",
            S = "purple",
            ["\19"] = "purple", -- this is an actual ^S, type <C-v><C-s> in insert mode
            R = "orange",
            r = "orange",
            ["!"] = "red",
            t = "green",
        },
        mode_color = function(self)
            local mode = conditions.is_active() and vim.fn.mode() or "n"
            return self.mode_colors[mode]
        end,
    },
    init = utils.pick_child_on_condition,
    GitStatusline,
    SpecialStatusline,
    InactiveStatusline,
    DefaultStatusline,
}
require("heirline").setup({
    statusline = StatusLines
})
