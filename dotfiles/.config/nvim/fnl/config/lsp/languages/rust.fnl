(let [blink-cmp (require :blink.cmp)]
  (set vim.g.rustaceanvim
       {:server {:capabilities (blink-cmp.get_lsp_capabilities)
                 :on_attach (fn [client bufnr]
                              (vim.lsp.inlay_hint.enable true {:bufnr bufnr}))
                 :default_settings {:rust-analyzer {:check {:command :clippy}
                                                    :diagnostics {:enable true
                                                                  :experimental {:enable true}}
                                                    :cargo {:allFeatures true}
                                                    :checkOnSave true}}}}))

(vim.lsp.enable :rust_analyzer false)
