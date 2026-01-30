(let [fzf (require :fzf-lua)]
  (fzf.setup {:profile :fzf-native
              :files {:color_icons true :file_icons true :multiprocess true}
              :winopts {:col 0.3 :height 0.4 :row 0.99 :width 0.93}}))

(let [wk (require :which-key)]
  (wk.add [{1 :<leader>fb
            2 "<cmd>FzfLua buffers<CR>"
            :desc "Find buffers"
            :mode :n
            :group :Find}
           {1 :<leader><leader>
            2 "<cmd>FzfLua files<CR>"
            :desc "Find files"
            :mode :n
            :group "Find Files"}
           {1 :<leader>fg
            2 "<cmd>FzfLua live_grep<CR>"
            :desc "Live Grep"
            :mode :n
            :group :Find}]))
