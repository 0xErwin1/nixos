(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :gopls 
                  {:capabilities (blink-cmp.get_lsp_capabilities)})
  (vim.lsp.enable :gopls))
