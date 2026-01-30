(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :docker_language_server 
                  {:capabilities (blink-cmp.get_lsp_capabilities)
                   :cmd [:docker-language-server :--stdio]
                   :filetypes [:dockerfile]})
  (vim.lsp.enable :docker_language_server))
