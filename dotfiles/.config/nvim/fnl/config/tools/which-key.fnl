(let [wk (require :which-key)]
  (wk.setup {:preset :helix
             :spec [{1 :<leader><leader> :group :Explore}
                    {1 :<leader>b :group :Buffer :icon "󰈙"}
                    {1 :<leader>d :group :Diagnostic :icon "󰌵"}
                    {1 :<leader>D :group :Debug :icon "󰗼"}
                    {1 :<leader>f :group :Find}
                    {1 :<leader>c :group :Code}
                    {1 :<M-t> :group :Terminal}
                    {1 :<leader>a :group :AI :icon "󰒡"}
                    {1 :<leader>s :group "take Screenshot"}]}))
