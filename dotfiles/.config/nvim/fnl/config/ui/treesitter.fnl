(let [treesitter (require :nvim-treesitter.configs)]
  (treesitter.setup {:ensure_installed :all
                     :ignore_install [:ipkg]
                     :auto_install true
                     :highlight {:enable true
                                 :use_languagetree true
                                 :additional_vim_regex_highlighting [:markdown]}
                     :indent {:enable true}
                     :matchup {:enable true}
                     :autotag {:enable true}
                     :tree_docs {:enable true}
                     :context_commentstring {:enable true
                                             :config {:typescript "// %s"
                                                      :css "/* %s */"
                                                      :scss "/* %s */"
                                                      :html "<!-- %s -->"
                                                      :lua "-- %s"
                                                      :bash "# %s"
                                                      :ignis "// %s"}}
                     :refactor {:enable true
                                :highlight_definitions {:enable true}
                                :highlight_current_scope {:enable false}}
                     :rainbow {:enable true
                               :extended_mode true
                               :max_file_lines 1000}}))

(let [parser-config ((. (require :nvim-treesitter.parsers) :get_parser_configs))]
  (set parser-config.ignis
       {:filetype [:Ignis :ignis]
        :install_info {:branch :main
                       :files [:src/parser.c]
                       :url "https://github.com/Ignis-lang/tree-sitter-ignis.git"}}))

