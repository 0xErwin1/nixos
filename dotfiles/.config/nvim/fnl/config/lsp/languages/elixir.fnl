(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :elixirls 
                  {:capabilities (blink-cmp.get_lsp_capabilities)
                   :cmd [:elixir-ls]})
  (vim.lsp.enable :elixirls))
