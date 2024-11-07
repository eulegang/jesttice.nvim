local M = {}
local opts = {}

local diag_namespace = vim.api.nvim_create_namespace("jesttice")

--- @param base string
--- @param file string
--- @param buf number
--- @param jest JestResult
function M.report_test_diagnostics(base, file, buf, jest)
  vim.diagnostic.reset(diag_namespace, buf)

  for _, result in pairs(jest.testResults) do
    for _, assert in pairs(result.assertionResults) do
      for _, message in pairs(assert.failureMessages) do
        local pat = file .. ":(%d+):(%d+)"
        local _, _, row, col = string.find(message, pat)
        vim.diagnostic.set(diag_namespace, buf, {
          {
            lnum = tonumber(row) - 1,
            col = tonumber(col) - 1,
            message = message,
            severity = vim.diagnostic.severity.ERROR,
            source = "jesttice",
          }
        })
      end
    end
  end
end

--- @param base string
--- @param file string
--- @param buf number
--- @param jest JestResult
function M.report_test_signs(base, file, buf, jest)
  local tree = vim.treesitter.get_parser(buf):parse(true)[1]
  local query = vim.treesitter.query.get("typescript", "jesttice-test")

  local node = tree:root()

  if query ~= nil and tree ~= nil then
    for id, n in query:iter_captures(node, buf, 0, -1) do
      if id == 2 then
        local srow, _, _ = n:start()
        local erow, _, _ = n:end_()
        srow = srow + 1
        erow = erow + 1

        local pass = true

        for _, result in ipairs(jest.testResults) do
          for _, assert in pairs(result.assertionResults) do
            for _, message in pairs(assert.failureMessages) do
              local _, _, row, _ = message:find(file .. ":(%d+):(%d+)")

              if srow <= tonumber(row) and tonumber(row) <= erow then
                pass = false
              end
            end
          end
        end

        local t = pass and "JestticePass" or "JestticeFail"
        local lnum = srow

        vim.fn.sign_place(0, "jesttice", t, buf, {
          lnum = lnum,
          priority = 5
        })
      end
    end
  end
end

--- @param base string
--- @param file string
--- @param buf number
--- @param jest JestResult
function M.report_coverage_signs(base, file, buf, jest)
  local coverage = jest.coverageMap[base .. "/" .. file]

  vim.fn.sign_unplace("jesttice", { buffer = buf })

  for spot, hits in pairs(coverage.s) do
    local t = hits == 0 and "JestticeUncovered" or "JestticeCovered"
    local lnum = coverage.statementMap[spot].start.line

    vim.fn.sign_place(0, "jesttice", t, buf, {
      lnum = lnum,
      priority = 5
    })
  end
end

--- @param jest JestResult
local function report_summary(jest)
  vim.notify("passed " .. jest.numPassedTests .. " / " .. jest.numTotalTests, vim.log.levels.INFO)
end

--- @param jest JestResult
--- @param code string
--- @param test string
--- @param success boolean
function M.report(jest, base, code, test, success)
  local test_buf = vim.fn.bufadd(test)
  local code_buf = vim.fn.bufadd(code)

  report_test_diagnostics(base, test, test_buf, jest)
  report_test_signs(base, test, test_buf, jest)
  report_coverage_signs(base, code, code_buf, jest)
  report_summary(jest)
end

--- @param o Configuration
function M.configure(o)
  opts = o

  vim.diagnostic.config({
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = '',
      }
    }
  }, diag_namespace)

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

  vim.fn.sign_define("JestticePass", {
    text = "✓",
    texthl = "Property",
  })

  vim.fn.sign_define("JestticeFail", {
    text = "!",
    texthl = "Error",
  })
end

return M
