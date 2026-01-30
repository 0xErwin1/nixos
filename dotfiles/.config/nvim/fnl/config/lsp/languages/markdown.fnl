; (let [render (require :render-markdown)]
;   (render.setup {:latex {:enable false}
;                  :custom {:started {:raw "[>]"
;                                     :rendered ""
;                                     :highlight :RenderMarkdownTableHead}
;                           :deleted {:raw "[~]"
;                                     :rendered ""
;                                     :highlight :RenderMarkdownError}
;                           :waiting {:raw "[@]"
;                                     :rendered "󰥔 "
;                                     :highlight :RenderMarkdownInfo}}}))

(let [blink-cmp (require :blink.cmp)]
  (vim.lsp.config :ltex
                  {:capabilities (blink-cmp.get_lsp_capabilities)
                   :cmd_env {:_JAVA_OPTIONS (.. (or vim.env._JAVA_OPTIONS "")
                                                " -Djdk.xml.totalEntitySizeLimit=0"
                                                " --enable-native-access=ALL-UNNAMED"
                                                " --add-opens=java.base/java.lang=ALL-UNNAMED"
                                                " --add-opens=java.base/java.util=ALL-UNNAMED"
                                                " -Dorg.slf4j.simpleLogger.defaultLogLevel=off"
                                                " -Dsun.misc.Unsafe.disableWarnings=true")}
                   :flags {:debounce_text_changes 500}
                   :filetypes [:latex
                               :tex
                               :bib
                               :markdown
                               :gitcommit
                               :text
                               :org
                               :norg]
                   :settings {:ltex {:enabled [:latex
                                               :tex
                                               :bib
                                               :markdown
                                               :gitcommit
                                               :text
                                               :org
                                               :norg]
                                     :language :auto
                                     :dictionary {:es-ES [":/home/iperez/.config/nvim/dict/es"]}
                                     :additionalRules {:enablePickyRules true
                                                       :motherTongue :es}}}})
  (vim.lsp.enable :ltex))

