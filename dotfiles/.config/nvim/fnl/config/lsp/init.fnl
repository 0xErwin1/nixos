(let [fidget (require :fidget)]
  (fidget.setup))

(let [lsp_signature (require :lsp_signature)]
  (lsp_signature.setup {:bind true
                        :max_height 10
                        :max_width 70
                        :noice true
                        :wrap true
                        :floating_window true}))

(vim.api.nvim_create_autocmd :LspAttach
                             {:callback (fn [args]
                                          (local client
                                                 (assert (vim.lsp.get_client_by_id args.data.client_id)))
                                          (when (client:supports_method :textDocument/inlayHint)
                                            (vim.lsp.inlay_hint.enable true {:bufnr args.buf}))
                                          (when (client:supports_method :textDocument/documentSymbol)
                                            (let [navic (require :nvim-navic)]
                                              (navic.attach client args.buf)))
                                          (vim.keymap.set :n :gd
                                                          "<cmd>lua vim.lsp.buf.definition()<CR>"
                                                          {:desc "Go to definition"})
                                          (vim.keymap.set :n :gi
                                                          "<cmd>lua vim.lsp.buf.implementation()<CR>"
                                                          {:desc "Go to implementation"})
                                          (vim.keymap.set :n :gr
                                                          "<cmd>lua vim.lsp.buf.references()<CR>"
                                                          {:desc "Go to references"}))
                              :group (vim.api.nvim_create_augroup :lsp {})})

(vim.keymap.set [:n :v] :<leader>ca "<cmd>FzfLua lsp_code_actions<CR>"
                {:desc "Code actions" :silent true})

(vim.keymap.set :n :<leader>cd "<cmd>lua vim.diagnostic.open_float()<CR>"
                {:desc "Line diagnostics"})

(vim.keymap.set :n :<leader>cr "<cmd>lua vim.lsp.buf.rename()<CR>"
                {:desc :Rename})

(vim.keymap.set :n :<leader>dD "<cmd>lua vim.diagnostic.goto_next()<CR>"
                {:desc "Next diagnostic"})

(vim.keymap.set :n :<leader>dE
                "<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR})<CR>"
                {:desc "Next Error"})

(vim.keymap.set :n :<leader>dW
                "<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.WARN})<CR>"
                {:desc "Next Warning"})

(vim.keymap.set :n :<leader>dd "<cmd>lua vim.diagnostic.goto_prev()<CR>"
                {:desc "Previous Diagnostic"})

(vim.keymap.set :n :<leader>de
                "<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR})<CR>"
                {:desc "Previous Error"})

(vim.keymap.set :n :<leader>dw
                "<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.WARN})<CR>"
                {:desc "Previous Warning"})

(vim.keymap.set :n :<leader>fr "<cmd>FzfLua lsp_references<CR>"
                {:desc "Find References"})

(vim.keymap.set :n :<leader>fi "<cmd>FzfLua lsp_implementations<CR>"
                {:desc "Go to Implementation"})

(vim.keymap.set :n :<leader>fs "<cmd>FzfLua lsp_live_workspace_symbols<CR>"
                {:desc "Workspace Symbols"})

(vim.keymap.set :n :<leader>fD "<cmd>FzfLua lsp_workspace_diagnostics<CR>"
                {:desc "Workspace Diagnostics"})

(vim.keymap.set :n :<leader>fd "<cmd>FzfLua lsp_document_diagnostics<CR>"
                {:desc "Document Diagnostics"})

(require :config.lsp.mason)
(require :config.lsp.cmp)
(require :config.lsp.conform)
(require :config.lsp.languages)


(let [blink-cmp (require :blink.cmp)
      util (require :lspconfig.util)] ; solo si querés root_dir tipo lspconfig
  (vim.lsp.config :ignis
    {:capabilities (blink-cmp.get_lsp_capabilities)
     :cmd ["ignis" "lsp"]
     :filetypes [:ignis :ign]            ; o [:ign] si tu ft es "ign"
     :root_dir (fn [fname]
                 ;; elegí los markers reales de tu proyecto
                 ((util.root_pattern "ignis.toml" ".git") fname))
     :flags {:debounce_text_changes 150}})

  (vim.lsp.enable :ignis))
