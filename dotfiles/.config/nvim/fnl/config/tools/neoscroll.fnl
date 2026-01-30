(let [neoscroll (require :neoscroll)]
  (neoscroll.setup {:cursor_scrolls_alone true
                    :easing :lineal
                    :hide_cursor true
                    :mappings []
                    :respect_scrolloff false
                    :stop_eof true})
  (let [keymap {:<M-k> (fn []
                         (neoscroll.scroll (- vim.wo.scroll)
                                           {:move_cursor true :duration 10}))
                :<M-j> (fn []
                         (neoscroll.scroll vim.wo.scroll
                                           {:move_cursor true :duration 10}))
                :zb (fn [] (neoscroll.zb {:half_win_duration 0}))
                :zt (fn [] (neoscroll.zt {:half_win_duration 0}))
                :zz (fn [] (neoscroll.zz {:half_win_duration 0}))}]
    (each [key func (pairs keymap)] (vim.keymap.set [:n :v :x] key func))))
