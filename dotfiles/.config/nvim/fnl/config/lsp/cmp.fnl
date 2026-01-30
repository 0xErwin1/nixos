(local kinds {:Supermaven " "
              :Copilot " "
              :Array "󰕤 "
              :Boolean " "
              :Class " "
              :Color " "
              :Constant " "
              :Constructor " "
              :Enum " "
              :EnumMember " "
              :Event "󱐋"
              :Field " "
              :File " "
              :Folder " "
              :Function "󰘧"
              :Interface " "
              :Key " "
              :Keyword " "
              :Method " "
              :Module " "
              :Namespace " "
              :Null "󰟢"
              :Number " "
              :Object " "
              :Operator " "
              :Package " "
              :Property "󱕴"
              :Reference " "
              :Snippet " "
              :String "󰅳 "
              :Struct " "
              :Text "󰦪"
              :TypeParameter "󰡱 "
              :Unit " "
              :Value " "
              :Variable "󰫧 "
              :Macro "󱃖 "})

(let [blink-cmp (require :blink.cmp)]
  (blink-cmp.setup {:keymap {:preset :enter
                             :<C-j> [:select_next :fallback]
                             :<C-k> [:select_prev :fallback]
                             :<Tab> [:select_next :fallback]
                             :<S-Tab> [:select_prev :fallback]
                             :<CR> [:accept :fallback]
                             :<C-Space> [:show
                                         :show_documentation
                                         :hide_documentation]
                             :<C-e> [:hide :fallback]
                             :<C-u> [:scroll_documentation_up :fallback]
                             :<C-d> [:scroll_documentation_down :fallback]
                             :<C-b> [:scroll_documentation_up :fallback]
                             :<C-f> [:scroll_documentation_down :fallback]}
                    :appearance {:nerd_font_variant :mono :kind_icons kinds}
                    :completion {:menu {:border :rounded :scrollbar true :draw { :treesitter [:lsp]}}
                                 :documentation {:auto_show true
                                                 :update_delay_ms 50
                                                 :auto_show_delay_ms 50}
                                 :ghost_text {:enabled true}}
                    :sources {:default [:lsp :path :snippets :buffer]}
                    :cmdline {:completion {:ghost_text {:enabled true}}}
                    :signature {:enabled true
                                :window {:show_documentation true}}}))
