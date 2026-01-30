(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :zls 
                  {:capabilities (blink-cmp.get_lsp_capabilities)})
  (vim.lsp.enable :zls))
