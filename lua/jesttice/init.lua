local testswitch = require("testswitch")
local str = require("string")

local group = nil
local diag_namespace = vim.api.nvim_create_namespace("jesttice")

--- @class AssertionResult
--- @field title string
--- @field failureMessages string[]

--- @class TestResults
--- @field success boolean
--- @field assertionResults AssertionResult[]


--- @class Coverage
--- @field statementMap { [string]: { start: { line: number, column: number }, end: { line: number, column: number } } }
--- @field s { [string]: number }

--- @param data { numPassedTests: number, numTotalTests: number, testResults: TestResults[], coverageMap: { [string]: Coverage } }
--- @param code string
--- @param test string
--- @param success boolean
local function report(data, base, code, test, success)
  local test_buf = vim.fn.bufadd(test)
  local code_buf = vim.fn.bufadd(code)
  vim.diagnostic.reset(diag_namespace, test_buf)

  for _, result in pairs(data.testResults) do
    for _, assert in pairs(result.assertionResults) do
      for _, message in pairs(assert.failureMessages) do
        local pat = test .. ":(%d+):(%d+)"
        local _, _, row, col = string.find(message, pat)
        vim.diagnostic.set(diag_namespace, test_buf, {
          {
            lnum = tonumber(row) - 1,
            col = tonumber(col) - 1,
            message = message,
            severity = vim.diagnostic.severity.ERROR,
            source = "jesttice"
          }
        })
      end
    end
  end

  local coverage = data.coverageMap[base .. "/" .. code]

  vim.fn.sign_unplace("jesttice", { buffer = code_buf })

  for spot, hits in pairs(coverage.s) do
    local t = hits == 0 and "JestticeUncovered" or "JestticeCovered"
    local lnum = coverage.statementMap[spot].start.line

    vim.fn.sign_place(0, "jesttice", t, code_buf, {
      lnum = lnum,
      priority = 5
    })
  end

  print(vim.inspect(coverage))

  print("passed " .. data.numPassedTests .. " / " .. data.numTotalTests)
end

--- @class Configuration
--- @field config string | nil
--- @field purge boolean | nil

--- @param opts Configuration
local function setup(opts)
  vim.fn.mkdir(vim.fn.stdpath("state") .. "/jesttice/output", "p")

  group = vim.api.nvim_create_augroup("jesttice", { clear = true })

  vim.fn.sign_define("JestticeCovered",
    {
      text = "█",
      texthl = "Statement",
    })

  vim.fn.sign_define("JestticeUncovered",
    {
      text = "█",
      texthl = "Error",
    })

  vim.api.nvim_create_autocmd({ "BufWrite" }, {
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

      local base = vim.fn.getcwd()
      local key = str.gsub(base .. '/' .. code, "/", "#")
      local output = vim.fn.stdpath("state") .. "/jesttice/output/" .. key


      local cmd = "npx jest --coverage --json --outputFile " .. output
      if opts.config ~= nil then
        cmd = cmd .. " --config " .. opts.config
      end

      vim.fn.jobstart(cmd, {
        on_exit = function(_, status)
          local success = status == 0
          local data = vim.fn.json_decode(vim.fn.readfile(output))
          if opts.purge ~= false then
            vim.fn.delete(output)
          end

          report(data, base, code, test, success)
        end,
      })
    end
  })
end

return {
  setup = setup
}
