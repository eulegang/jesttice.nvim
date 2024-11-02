local reporter = require("jesttice.reporter")

local M = {}

local running = {}
local opts = {}

--- @param test string
--- @param code string
function M.start(test, code)
  local base = vim.fn.getcwd()
  --- @type string
  local resolved = base .. '/' .. code
  local key = resolved:gsub("/", "#")
  local output = vim.fn.stdpath("state") .. "/jesttice/output/" .. key

  local cmd = "npx jest --coverage --json " .. test .. " --outputFile " .. output
  if opts.config ~= nil then
    cmd = cmd .. " --config " .. opts.config
  end

  vim.notify("running " .. cmd, vim.log.levels.INFO)

  local job = vim.fn.jobstart(cmd, {
    on_exit = function(_, status)
      local success = status == 0
      local data = vim.fn.json_decode(vim.fn.readfile(output))
      if opts.purge ~= false then
        vim.fn.delete(output)
      end

      reporter.report(data, base, code, test, success)
      if opts.on_finish ~= nil then
        opts.on_finish(running[key])
      end

      running[key] = nil
    end,
  })

  running[key] = {
    code = code,
    test = test,
    job = job,
  }

  if opts.on_start ~= nil then
    opts.on_start(running[key])
  end
end

--- @param o Configuration
function M.configure(o)
  opts = o
  vim.fn.mkdir(vim.fn.stdpath("state") .. "/jesttice/output", "p")
end

return M
