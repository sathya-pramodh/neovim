local t = require('test.testutil')
local n = require('test.functional.testnvim')()

local tt = require('test.functional.testterm')
local clear, eq, eval = n.clear, t.eq, n.eval
local feed, api, command = n.feed, n.api, n.command
local feed_data = tt.feed_data
local is_os = t.is_os
local skip = t.skip

describe(':terminal mouse', function()
  local screen

  before_each(function()
    clear()
    api.nvim_set_option_value('statusline', '==========', {})
    screen = tt.setup_screen()
    command('highlight StatusLine NONE')
    command('highlight StatusLineNC NONE')
    command('highlight StatusLineTerm NONE')
    command('highlight StatusLineTermNC NONE')
    command('highlight VertSplit NONE')
    local lines = {}
    for i = 1, 30 do
      table.insert(lines, 'line' .. tostring(i))
    end
    table.insert(lines, '')
    feed_data(lines)
    screen:expect([[
      line26                                            |
      line27                                            |
      line28                                            |
      line29                                            |
      line30                                            |
      ^                                                  |
      {5:-- TERMINAL --}                                    |
    ]])
  end)

  describe('when the terminal has focus', function()
    it('will exit focus on mouse-scroll', function()
      eq('t', eval('mode(1)'))
      feed('<ScrollWheelUp><0,0>')
      eq('nt', eval('mode(1)'))
    end)

    it('will exit focus and trigger Normal mode mapping on mouse click', function()
      feed([[<C-\><C-N>qri]])
      command('let g:got_leftmouse = 0')
      command('nnoremap <LeftMouse> <Cmd>let g:got_leftmouse = 1<CR>')
      eq('t', eval('mode(1)'))
      eq(0, eval('g:got_leftmouse'))
      feed('<LeftMouse>')
      eq('nt', eval('mode(1)'))
      eq(1, eval('g:got_leftmouse'))
      feed('q')
      eq('i<LeftMouse>', eval('keytrans(@r)'))
    end)

    it('will exit focus and trigger Normal mode mapping on mouse click with modifier', function()
      feed([[<C-\><C-N>qri]])
      command('let g:got_ctrl_leftmouse = 0')
      command('nnoremap <C-LeftMouse> <Cmd>let g:got_ctrl_leftmouse = 1<CR>')
      eq('t', eval('mode(1)'))
      eq(0, eval('g:got_ctrl_leftmouse'))
      feed('<C-LeftMouse>')
      eq('nt', eval('mode(1)'))
      eq(1, eval('g:got_ctrl_leftmouse'))
      feed('q')
      eq('i<C-LeftMouse>', eval('keytrans(@r)'))
    end)

    it('will exit focus on <C-\\> + mouse-scroll', function()
      eq('t', eval('mode(1)'))
      feed('<C-\\>')
      feed('<ScrollWheelUp><0,0>')
      eq('nt', eval('mode(1)'))
    end)

    it('will not exit focus on left-release', function()
      eq('t', eval('mode(1)'))
      feed('<LeftRelease><0,0>')
      eq('t', eval('mode(1)'))
      command('setlocal number')
      eq('t', eval('mode(1)'))
      feed('<LeftRelease><0,0>')
      eq('t', eval('mode(1)'))
    end)

    it('will not exit focus on mouse movement', function()
      eq('t', eval('mode(1)'))
      feed('<MouseMove><0,0>')
      eq('t', eval('mode(1)'))
      command('setlocal number')
      eq('t', eval('mode(1)'))
      feed('<MouseMove><0,0>')
      eq('t', eval('mode(1)'))
    end)

    describe('with mouse events enabled by the program', function()
      before_each(function()
        tt.enable_mouse()
        tt.feed_data('mouse enabled\n')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
          ^                                                  |
          {5:-- TERMINAL --}                                    |
        ]])
      end)

      it('will forward mouse press, drag and release to the program', function()
        skip(is_os('win'))
        feed('<LeftMouse><1,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
           "#^                                               |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftDrag><2,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
             @##^                                            |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftDrag><3,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
                @$#^                                         |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftRelease><3,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
                   #$#^                                      |
          {5:-- TERMINAL --}                                    |
        ]])
      end)

      it('will forward mouse scroll to the program', function()
        skip(is_os('win'))
        feed('<ScrollWheelUp><0,0>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
          `!!^                                               |
          {5:-- TERMINAL --}                                    |
        ]])
      end)

      it('dragging and scrolling do not interfere with each other', function()
        skip(is_os('win'))
        feed('<LeftMouse><1,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
           "#^                                               |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<ScrollWheelUp><1,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
             `"#^                                            |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftDrag><2,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
                @##^                                         |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<ScrollWheelUp><2,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
                   `##^                                      |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftRelease><2,2>')
        screen:expect([[
          line27                                            |
          line28                                            |
          line29                                            |
          line30                                            |
          mouse enabled                                     |
                      ###^                                   |
          {5:-- TERMINAL --}                                    |
        ]])
      end)

      it('will forward mouse clicks to the program with the correct even if set nu', function()
        skip(is_os('win'))
        command('set number')
        -- When the display area such as a number is clicked, it returns to the
        -- normal mode.
        feed('<LeftMouse><3,0>')
        eq('nt', eval('mode(1)'))
        screen:expect([[
          {121: 11 }^line28                                        |
          {121: 12 }line29                                        |
          {121: 13 }line30                                        |
          {121: 14 }mouse enabled                                 |
          {121: 15 }rows: 6, cols: 46                             |
          {121: 16 }                                              |
                                                            |
        ]])
        -- If click on the coordinate (0,1) of the region of the terminal
        -- (i.e. the coordinate (4,1) of vim), 'CSI !"' is sent to the terminal.
        feed('i<LeftMouse><4,1>')
        screen:expect([[
          {121: 11 }line28                                        |
          {121: 12 }line29                                        |
          {121: 13 }line30                                        |
          {121: 14 }mouse enabled                                 |
          {121: 15 }rows: 6, cols: 46                             |
          {121: 16 } !"^                                           |
          {5:-- TERMINAL --}                                    |
        ]])
      end)

      it('will lose focus if statusline is clicked', function()
        command('set laststatus=2')
        screen:expect([[
          line29                                            |
          line30                                            |
          mouse enabled                                     |
          rows: 5, cols: 50                                 |
          ^                                                  |
          ==========                                        |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftMouse><0,5>')
        screen:expect([[
          line29                                            |
          line30                                            |
          mouse enabled                                     |
          rows: 5, cols: 50                                 |
          ^                                                  |
          ==========                                        |
                                                            |
        ]])
        feed('<LeftDrag><0,4>')
        screen:expect([[
          mouse enabled                                     |
          rows: 5, cols: 50                                 |
          rows: 4, cols: 50                                 |
          ^                                                  |
          ==========                                        |
                                                            |*2
        ]])
      end)

      it('will lose focus if right separator is clicked', function()
        command('rightbelow vnew | wincmd p | startinsert')
        screen:expect([[
          line29                  │                         |
          line30                  │{100:~                        }|
          mouse enabled           │{100:~                        }|
          rows: 5, cols: 24       │{100:~                        }|
          ^                        │{100:~                        }|
          ==========               ==========               |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftMouse><24,0>')
        screen:expect([[
          line29                  │                         |
          line30                  │{100:~                        }|
          mouse enabled           │{100:~                        }|
          rows: 5, cols: 24       │{100:~                        }|
          ^                        │{100:~                        }|
          ==========               ==========               |
                                                            |
        ]])
        feed('<LeftDrag><23,0>')
        screen:expect([[
          line30                 │                          |
          mouse enabled          │{100:~                         }|
          rows: 5, cols: 24      │{100:~                         }|
          rows: 5, cols: 23      │{100:~                         }|
          ^                       │{100:~                         }|
          ==========              ==========                |
                                                            |
        ]])
      end)

      it('will lose focus if winbar/tabline is clicked', function()
        command('setlocal winbar=WINBAR')
        screen:expect([[
          {5:WINBAR                                            }|
          line29                                            |
          line30                                            |
          mouse enabled                                     |
          rows: 5, cols: 50                                 |
          ^                                                  |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftMouse><0,0>')
        screen:expect([[
          {5:WINBAR                                            }|
          line29                                            |
          line30                                            |
          mouse enabled                                     |
          rows: 5, cols: 50                                 |
          ^                                                  |
                                                            |
        ]])
        command('set showtabline=2 tabline=TABLINE | startinsert')
        screen:expect([[
          {2:TABLINE                                           }|
          {5:WINBAR                                            }|
          mouse enabled                                     |
          rows: 5, cols: 50                                 |
          rows: 4, cols: 50                                 |
          ^                                                  |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftMouse><0,0>')
        screen:expect([[
          {2:TABLINE                                           }|
          {5:WINBAR                                            }|
          mouse enabled                                     |
          rows: 5, cols: 50                                 |
          rows: 4, cols: 50                                 |
          ^                                                  |
                                                            |
        ]])
        command('setlocal winbar= | startinsert')
        screen:expect([[
          {2:TABLINE                                           }|
          mouse enabled                                     |
          rows: 5, cols: 50                                 |
          rows: 4, cols: 50                                 |
          rows: 5, cols: 50                                 |
          ^                                                  |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<LeftMouse><0,0>')
        screen:expect([[
          {2:TABLINE                                           }|
          mouse enabled                                     |
          rows: 5, cols: 50                                 |
          rows: 4, cols: 50                                 |
          rows: 5, cols: 50                                 |
          ^                                                  |
                                                            |
        ]])
      end)
    end)

    describe('with a split window and other buffer', function()
      before_each(function()
        feed('<c-\\><c-n>:vsp<cr>')
        screen:expect([[
          line28                   │line28                  |
          line29                   │line29                  |
          line30                   │line30                  |
          rows: 5, cols: 25        │rows: 5, cols: 25       |
          ^                         │                        |
          ==========                ==========              |
          :vsp                                              |
        ]])
        feed(':enew | set number<cr>')
        screen:expect([[
          {121:  1 }^                     │line29                  |
          {100:~                        }│line30                  |
          {100:~                        }│rows: 5, cols: 25       |
          {100:~                        }│rows: 5, cols: 24       |
          {100:~                        }│                        |
          ==========                ==========              |
          :enew | set number                                |
        ]])
        feed('30iline\n<esc>')
        screen:expect([[
          {121: 27 }line                 │line29                  |
          {121: 28 }line                 │line30                  |
          {121: 29 }line                 │rows: 5, cols: 25       |
          {121: 30 }line                 │rows: 5, cols: 24       |
          {121: 31 }^                     │                        |
          ==========                ==========              |
                                                            |
        ]])
        feed('<c-w>li')
        screen:expect([[
          {121: 27 }line                 │line29                  |
          {121: 28 }line                 │line30                  |
          {121: 29 }line                 │rows: 5, cols: 25       |
          {121: 30 }line                 │rows: 5, cols: 24       |
          {121: 31 }                     │^                        |
          ==========                ==========              |
          {5:-- TERMINAL --}                                    |
        ]])

        -- enabling mouse won't affect interaction with other windows
        tt.enable_mouse()
        tt.feed_data('mouse enabled\n')
        screen:expect([[
          {121: 27 }line                 │line30                  |
          {121: 28 }line                 │rows: 5, cols: 25       |
          {121: 29 }line                 │rows: 5, cols: 24       |
          {121: 30 }line                 │mouse enabled           |
          {121: 31 }                     │^                        |
          ==========                ==========              |
          {5:-- TERMINAL --}                                    |
        ]])
      end)

      it("scrolling another window keeps focus and respects 'mousescroll'", function()
        feed('<ScrollWheelUp><4,0><ScrollWheelUp><4,0>')
        screen:expect([[
          {121: 21 }line                 │line30                  |
          {121: 22 }line                 │rows: 5, cols: 25       |
          {121: 23 }line                 │rows: 5, cols: 24       |
          {121: 24 }line                 │mouse enabled           |
          {121: 25 }line                 │^                        |
          ==========                ==========              |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<S-ScrollWheelDown><4,0>')
        screen:expect([[
          {121: 26 }line                 │line30                  |
          {121: 27 }line                 │rows: 5, cols: 25       |
          {121: 28 }line                 │rows: 5, cols: 24       |
          {121: 29 }line                 │mouse enabled           |
          {121: 30 }line                 │^                        |
          ==========                ==========              |
          {5:-- TERMINAL --}                                    |
        ]])
        command('set mousescroll=ver:10')
        feed('<ScrollWheelUp><0,0>')
        screen:expect([[
          {121: 16 }line                 │line30                  |
          {121: 17 }line                 │rows: 5, cols: 25       |
          {121: 18 }line                 │rows: 5, cols: 24       |
          {121: 19 }line                 │mouse enabled           |
          {121: 20 }line                 │^                        |
          ==========                ==========              |
          {5:-- TERMINAL --}                                    |
        ]])
        command('set mousescroll=ver:0')
        feed('<ScrollWheelUp><0,0>')
        screen:expect_unchanged()
        feed([[<C-\><C-N><C-W>w]])
        command('setlocal nowrap')
        feed('0<C-V>gg3ly$4p<C-W>wi')
        screen:expect([[
          {121:  1 }linelinelinelineline │line30                  |
          {121:  2 }linelinelinelineline │rows: 5, cols: 25       |
          {121:  3 }linelinelinelineline │rows: 5, cols: 24       |
          {121:  4 }linelinelinelineline │mouse enabled           |
          {121:  5 }linelinelinelineline │^                        |
          ==========                ==========              |
          {5:-- TERMINAL --}                                    |
        ]])
        feed('<ScrollWheelRight><4,0>')
        screen:expect([[
          {121:  1 }nelinelineline       │line30                  |
          {121:  2 }nelinelineline       │rows: 5, cols: 25       |
          {121:  3 }nelinelineline       │rows: 5, cols: 24       |
          {121:  4 }nelinelineline       │mouse enabled           |
          {121:  5 }nelinelineline       │^                        |
          ==========                ==========              |
          {5:-- TERMINAL --}                                    |
        ]])
        command('set mousescroll=hor:4')
        feed('<ScrollWheelLeft><4,0>')
        screen:expect([[
          {121:  1 }nelinelinelineline   │line30                  |
          {121:  2 }nelinelinelineline   │rows: 5, cols: 25       |
          {121:  3 }nelinelinelineline   │rows: 5, cols: 24       |
          {121:  4 }nelinelinelineline   │mouse enabled           |
          {121:  5 }nelinelinelineline   │^                        |
          ==========                ==========              |
          {5:-- TERMINAL --}                                    |
        ]])
      end)

      it('will lose focus if another window is clicked', function()
        feed('<LeftMouse><5,1>')
        screen:expect([[
          {121: 27 }line                 │line30                  |
          {121: 28 }l^ine                 │rows: 5, cols: 25       |
          {121: 29 }line                 │rows: 5, cols: 24       |
          {121: 30 }line                 │mouse enabled           |
          {121: 31 }                     │                        |
          ==========                ==========              |
                                                            |
        ]])
      end)

      it('handles terminal size when switching buffers', function()
        api.nvim_set_option_value('hidden', true, {})
        feed('<c-\\><c-n><c-w><c-w>')
        screen:expect([[
          {121: 27 }line                 │line30                  |
          {121: 28 }line                 │rows: 5, cols: 25       |
          {121: 29 }line                 │rows: 5, cols: 24       |
          {121: 30 }line                 │mouse enabled           |
          {121: 31 }^                     │                        |
          ==========                ==========              |
                                                            |
        ]])
        feed(':bn<cr>')
        screen:expect([[
          rows: 5, cols: 25        │rows: 5, cols: 25       |
          rows: 5, cols: 24        │rows: 5, cols: 24       |
          mouse enabled            │mouse enabled           |
          rows: 5, cols: 25        │rows: 5, cols: 25       |
          ^                         │                        |
          ==========                ==========              |
          :bn                                               |
        ]])
        feed(':bn<cr>')
        screen:expect([[
          {121: 27 }line                 │rows: 5, cols: 24       |
          {121: 28 }line                 │mouse enabled           |
          {121: 29 }line                 │rows: 5, cols: 25       |
          {121: 30 }line                 │rows: 5, cols: 24       |
          {121: 31 }^                     │                        |
          ==========                ==========              |
          :bn                                               |
        ]])
      end)
    end)
  end)
end)
