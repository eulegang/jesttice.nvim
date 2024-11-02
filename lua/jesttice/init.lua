local testswitch = require("testswitch")
local watch = require("jesttice.watch")
local runner = require("jesttice.runner")
local reporter = require("jesttice.reporter")

--- @class JestResult
--- @field numPassedTests number
--- @field numTotalTests number
--- @field testResults TestResults[]
--- @field coverageMap { [string]: Coverage }

--- @class TestResults
--- @field success boolean
--- @field assertionResults AssertionResult[]

---@class AssertionResult
---@field failureMessages string[]

--- @class Coverage
--- @field statementMap { [string]: { start: { line: number, column: number }, end: { line: number, column: number } } }
--- @field s { [string]: number }


--- @class Configuration
--- @field config string | nil
--- @field purge boolean | nil

--- @param opts Configuration
local function setup(opts)
  reporter.configure(opts)
  runner.configure(opts)
  watch.enable()
end

return {
  setup = setup,
  disable = watch.disable,
  enable = watch.enable,
  toggle = watch.toggle,
}
