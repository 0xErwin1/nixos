(let [mason (require :mason)]
  (mason.setup {}))

(let [mason-lspconfig (require :mason-lspconfig)]
  (mason-lspconfig.setup {:ensure_installed [
                                             :gopls
                                             :jdtls
                                             :lua_ls
                                             :rust_analyzer
                                             :pyright
                                             :ts_ls
                                             :vuels
                                             :yamlls
                                             :zls]
                          :automatic_installation { :exclude ["rust_analyzer"] }}))
