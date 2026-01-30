(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :lua_ls
                  {:capabilities (blink-cmp.get_lsp_capabilities)
                   :settings {:Lua {:completion {:callSnippet :Replace}
                                    :telemetry {:enable false}
                                    :runtime {:version :LuaJIT}
                                    :diagnostics {:globals [:vim]}}}})
  (vim.lsp.enable :lua_ls))

(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :fennel_ls
                  {:capabilities (blink-cmp.get_lsp_capabilities)})
  (vim.lsp.enable :fennel_ls))
