local stub = require("luassert.stub")
local match = require("luassert.match")
local mod = require("jesttice.reporter")

local function is_set(state, arguments)
  local k = arguments[1]
  local v = arguments[2]
  return function(val)
    local actual = val[1][k]

    if actual ~= nil and actual == v then
      return true
    else
      print("expected '" .. k .. "' to be " .. vim.inspect(v) .. " but was " .. vim.inspect(actual))
      return false
    end
  end
end

assert:register("matcher", "set", is_set)

describe("report", function()
  describe("test_diagnostics", function()
    local jest_result = {
      numTotalTests = 10,
      numPassedTests = 9,
      coverageMap = {},
      testResults = {
        {
          success = false,
          assertionResults = {
            {
              failureMessages = {
                "(src/base/tests/x.test.ts:30:24)"
              }
            }
          }
        }
      }
    }

    before_each(function()
      stub(vim.diagnostic, "reset")
      stub(vim.diagnostic, "set")
    end)

    it("should reset diagnostics", function()
      mod.report_test_diagnostics(vim.fn.getcwd(), "src/base/tests/x.test.ts", 3, jest_result)

      assert.spy(vim.diagnostic.reset).was.called_with(match._, 3)
    end)

    it("should set diagnostic", function()
      mod.report_test_diagnostics(vim.fn.getcwd(), "src/base/tests/x.test.ts", 3, jest_result)

      assert.spy(vim.diagnostic.set).was.called_with(match._, 3, match.all_of(
        match.is_set("source", "jesttice"),
        match.is_set("lnum", 29)
      ))
    end)
  end)

  describe("regex sigil in filename", function()
    local jest_result = {
      numTotalTests = 10,
      numPassedTests = 9,
      coverageMap = {},
      testResults = {
        {
          success = false,
          assertionResults = {
            {
              failureMessages = {
                "(src/base-api/tests/x.test.ts:30:24)"
              }
            }
          }
        }
      }
    }

    it("should set diagnostic", function()
      stub(vim.diagnostic, "reset")
      stub(vim.diagnostic, "set")

      mod.report_test_diagnostics(vim.fn.getcwd(), "src/base-api/tests/x.test.ts", 3, jest_result)

      assert.spy(vim.diagnostic.set).was.called_with(match._, 3, match.all_of(
        match.is_set("source", "jesttice"),
        match.is_set("lnum", 29)
      ))
    end)
  end)
end)
