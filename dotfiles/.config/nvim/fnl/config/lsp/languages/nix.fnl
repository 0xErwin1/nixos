(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :nixd 
                  {:capabilities (blink-cmp.get_lsp_capabilities)})
  (vim.lsp.enable :nixd))
