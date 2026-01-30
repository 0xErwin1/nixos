(let [indent (require :ibl)]
  (indent.setup {:indent {:char "|" :tab_char "."}
                 :scope {:enabled true
                         :show_start true
                         :show_end true
                         :injected_languages false
                         :highlight [:Function :Label]
                         :priority 500}}))
