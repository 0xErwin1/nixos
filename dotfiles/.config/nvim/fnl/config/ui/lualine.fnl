(let [lualine (require :lualine)]
  (lualine.setup {:options {:theme :auto
                            :globalstatus true
                            :icon_enabled true
                            :always_divide_middle true
                            :component_separators {:left "" :right ""}
                            :section_separators {:left "" :right ""}}
                  :sections {:lualine_a [{1 :mode :icon " " :upper true}]
                             :lualine_b [{1 :branch :icon ""}
                                         {1 :diff
                                          :colored true
                                          :always_visible true
                                          :symbols {:added " "
                                                    :modified " "
                                                    :removed " "}}]
                             :lualine_c [{}]
                             :lualine_x [{1 :diagnostics
                                          :sources [:nvim_diagnostic]
                                          :sections [:error :warn]
                                          :symbols {:error " "
                                                    :warn " "
                                                    :info " "
                                                    :hint " "}
                                          :colored true
                                          :update_in_insert true
                                          :always_visible true}]
                             :lualine_y [{1 :filetype
                                          :icons_enabled true
                                          :always_visible true
                                          :symbols {:unix :LF
                                                    :dos :CRLF
                                                    :mac :CR}}]
                             :lualine_z [:location]}}))
