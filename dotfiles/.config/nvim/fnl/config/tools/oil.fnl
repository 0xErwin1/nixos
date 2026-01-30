(let [oil (require :oil)]
  (oil.setup {:experimental_watch_for_changes true
              :delete_to_trash true
              :view_options {:show_hidden true}
              :float {:padding 10 :max_width 100 :max_height 100}
              :keymaps {:H :actions.parent :L :actions.select}}))

(let [wk (require :which-key)]
  (wk.add [{1 :<leader>e
            2 "<cmd>Oil --float<CR>"
            :desc "Open file explorer"
            :mode :n
            :group :Explore}]))
