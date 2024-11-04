local testswitch = require("testswitch")
local runner = require("jesttice.runner")

local group = vim.api.nvim_create_augroup("jesttice", { clear = true })

--- @type number | nil
local cmd = nil

local function enable()
  if cmd == nil then
    cmd = vim.api.nvim_create_autocmd({ "BufWrite" }, {
      pattern = { '*.js', '*.ts', '*.jsx', '*.tsx' },
      group = group,
      callback = function(args)
        local test, code
        if testswitch.is_test(args.file) then
          code = testswitch.counterpart(args.file)
          test = args.file
        else
          code = args.file
          test = testswitch.counterpart(args.file)
        end

        if test == nil or code == nil then
          vim.notify("not running test (no pair)", vim.log.levels.ERROR)
          return
        end

        runner.start(test, code)
      end
    })
  end
end

local function disable()
  if cmd ~= nil then
    vim.api.nvim_del_autocmd(cmd)
    cmd = nil
  end
end

local function toggle()
  if cmd == nil then
    enable()
  else
    disable()
  end
end

return {
  disable = disable,
  enable = enable,
  toggle = toggle
}
