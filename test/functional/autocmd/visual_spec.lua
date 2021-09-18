local helpers = require('test.functional.helpers')(after_each)

local clear = helpers.clear
local command = helpers.command
local eq = helpers.eq
local eval = helpers.eval
local feed = helpers.feed
local request = helpers.request

local function autocmd(event, cmd)
  command('autocmd! ' .. event .. ' * ' .. cmd)
end

local function autocmd_visualenter()
  autocmd('VisualEnter', 'let g:is_autocmd_triggered = 1')
end

local function autocmd_visualchange()
  autocmd('VisualChange', 'let g:is_autocmd_triggered = 1')
end

local function autocmd_visualleave()
  autocmd('VisualLeave', 'let g:is_autocmd_triggered = 1')
end

local function clear_autocmd(event)
   command('autocmd! ' .. event)
end

local function check_triggered()
  eq(1, eval("get(g:, 'is_autocmd_triggered')"))
end

local function reset()
  command('let g:is_autocmd_triggered = 0')
end

local function replace_keycodes(keycode)
  return request('nvim_replace_termcodes', keycode, true, false, true)
end

local CR = replace_keycodes('<CR>')
local ESC = replace_keycodes('<Esc>')
local CTRL_A = replace_keycodes('<C-a>')
local CTRL_C = replace_keycodes('<C-c>')
local CTRL_G = replace_keycodes('<C-g>')
local CTRL_H = replace_keycodes('<C-h>')
local CTRL_O = replace_keycodes('<C-o>')
local CTRL_V = replace_keycodes('<C-v>')
local CTRL_X = replace_keycodes('<C-x>')

describe('autocmd VisualEnter', function()
  before_each(function()
    clear()
    autocmd_visualenter()
  end)

  it('is triggered by Visual char-wise mode', function()
    feed('v')
    check_triggered()
  end)

  it('is triggered by Visual line-wise mode', function()
    feed('V')
    check_triggered()
  end)

  it('is triggered by Visual block-wise mode', function()
    feed(CTRL_V)
    check_triggered()
  end)

  it('is triggered by Select char-wise mode', function()
    feed('gh')
    check_triggered()
  end)

  it('is triggered by Select line-wise mode', function()
    feed('gH')
    check_triggered()
  end)

  it('is triggered by Select block-wise mode', function()
    feed('g', CTRL_H)
    check_triggered()
  end)

  -- `gv` always leaves you in Visual mode, but Select mode is briefly
  -- entered if it was the prior type, before ending in Visual mode.
  -- Check to ensure the mode is Visual when the autocommand triggers.
  it('is triggered by re-select previous visual area (`gv`)', function()
    clear_autocmd('VisualEnter')
    autocmd('VisualEnter', 'if nvim_get_mode().mode == "v" | let g:is_autocmd_triggered = 1 | endif')
    feed('gh', ESC)
    reset()
    feed('gv')
    check_triggered()
  end)

  it('is triggered by selecting the next result (`gn`)', function()
    feed('ofoo', ESC, 'gg/foo', CR)
    reset()
    feed('gn')
    check_triggered()
  end)

  it('is triggered by selecting the previous result (`gN`)', function()
    feed('ofoo', ESC, 'gg/foo', CR, 'G')
    reset()
    feed('gN')
    check_triggered()
  end)

  it('is triggered by Visual mode with a count', function()
    feed('ifoo', ESC, 'Vypp')
    reset()
    feed('3V')
    check_triggered()
  end)
end)

describe('autocmd VisualChange', function()
  before_each(function()
    clear()
    autocmd_visualchange()
  end)

  it('is triggered by switching from Visual char-wise mode to line-wise mode', function()
    feed('v')
    reset()
    feed('V')
    check_triggered()
  end)

  it('is triggered by switching from Visual char-wise mode to block-wise mode', function()
    feed('v')
    reset()
    feed(CTRL_V)
    check_triggered()
  end)

  it('is triggered by switching from Visual line-wise mode to char-wise mode', function()
    feed('V')
    reset()
    feed('v')
    check_triggered()
  end)

  it('is triggered by switching from Visual line-wise mode to block-wise mode', function()
    feed('V')
    reset()
    feed(CTRL_V)
    check_triggered()
  end)

  it('is triggered by switching from Visual block-wise mode to char-wise mode', function()
    feed(CTRL_V)
    reset()
    feed('v')
    check_triggered()
  end)

  it('is triggered by switching from Visual block-wise mode to line-wise mode', function()
    feed(CTRL_V)
    reset()
    feed('V')
    check_triggered()
  end)

  it('is triggered by switching from Visual mode to Select mode', function()
    feed('v')
    reset()
    feed(CTRL_G)
    check_triggered()
  end)

  it('is triggered by switching from Select mode to Visual mode', function()
    feed('gh')
    reset()
    feed(CTRL_G)
    check_triggered()
  end)

  -- Check both triggers: when entering Visual mode with `<C-o>`, and
  -- when going back to Select mode after the Visual motion.
  it('is triggered by switching from Select mode to transient Visual mode (`<C-o>`)', function()
    feed('gh')
    reset()
    feed(CTRL_O)
    check_triggered()

    reset()
    feed('h')
    check_triggered()
  end)
end)

describe('autocmd VisualLeave', function()
  before_each(function()
    clear()
    autocmd_visualleave()
  end)

  it('is triggered by exiting Visual mode with `<Esc>`', function()
    feed('v')
    reset()
    feed(ESC)
    check_triggered()
  end)

  it('is triggered by exiting Select mode with `<Esc>`', function()
    feed('gh')
    reset()
    feed(ESC)
    check_triggered()
  end)

  it('is triggered by exiting Visual mode with `<C-c>`', function()
    feed('v')
    reset()
    feed(CTRL_C)
    check_triggered()
  end)

  it('is triggered by exiting Select mode with `<C-c>`', function()
    feed('gh')
    reset()
    feed(CTRL_C)
    check_triggered()
  end)

  it('is triggered by exiting Visual mode after an operator', function()
    feed('v')
    reset()
    feed('y')
    check_triggered()
  end)

  it('is triggered by visually adding (`<C-a>`)', function()
    feed('v')
    reset()
    feed(CTRL_A)
    check_triggered()
  end)

  it('is triggered by visually adding with increments (`g<C-a>`)', function()
    feed('v')
    reset()
    feed('g', CTRL_A)
    check_triggered()
  end)

  it('is triggered by visually subtracting (`<C-x>`)', function()
    feed('v')
    reset()
    feed(CTRL_X)
    check_triggered()
  end)

  it('is triggered by visually subtracting with increments (`g<C-x>`)', function()
    feed('v')
    reset()
    feed('g', CTRL_X)
    check_triggered()
  end)

  it('s triggered by joining lines (`gJ`)', function()
    feed('v')
    reset()
    feed('gJ')
    check_triggered()
  end)

  it('is triggered by joining lines with spaces (`J`)', function()
    feed('v')
    reset()
    feed('J')
    check_triggered()
  end)
end)
