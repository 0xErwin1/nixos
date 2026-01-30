(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :clangd 
                  {:capabilities (blink-cmp.get_lsp_capabilities)})
  (vim.lsp.enable :clangd))
