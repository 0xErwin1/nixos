(let [gitsigns (require :gitsigns)]
  (gitsigns.setup {:current_line_blame true
                   :signs {:add {:text " "}
                           :change {:text " "}
                           :delete {:text " "}
                           :untracked {:text ""}
                           :topdelete {:text "󱂥 "}
                           :changedelete {:text "󱂧 "}}}))

(let [neogit (require :neogit)]
  (neogit.setup {:integrations {:diffview true}}))

(let [wk (require :which-key)]
  (wk.add [{1 :<leader>g
            2 :<CMD>Neogit<CR>
            :desc "Open Neogit"
            :mode :n
            :group :Git}]))
