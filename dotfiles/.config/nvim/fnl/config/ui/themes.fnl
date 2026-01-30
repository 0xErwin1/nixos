(let [ayu (require :ayu)]
  (ayu.setup {:mirage false}))

(let [tokyodark (require :tokyodark)]
  (tokyodark.setup {:gamma 1
                    :styles {:comments {:italic true}
                             :functions {:bold true :italic true}
                             :identifiers {:italic true}
                             :keywords {:bold true :italic true}
                             :variables {:bold true}}
                    :transparent_background true}))

(vim.cmd.colorscheme :ayu)

(vim.api.nvim_set_hl 0 :BlinkCmpMenu {:bg "#0F131A" :fg "#BFBDB6"})
(vim.api.nvim_set_hl 0 :BlinkCmpMenuBorder {:bg "#0F131A" :fg "#565B66"})
(vim.api.nvim_set_hl 0 :BlinkCmpMenuSelection {:bg "#1B3A5B" :fg "#E6B450"})
(vim.api.nvim_set_hl 0 :BlinkCmpLabel {:bg "#0F131A" :fg "#BFBDB6"})
(vim.api.nvim_set_hl 0 :BlinkCmpLabelMatch {:bg "#0F131A" :fg "#E6B450"})
(vim.api.nvim_set_hl 0 :BlinkCmpLabelDetail {:bg "#0F131A" :fg "#636A72"})
(vim.api.nvim_set_hl 0 :BlinkCmpLabelDescription {:bg "#0F131A" :fg "#636A72"})
(vim.api.nvim_set_hl 0 :BlinkCmpDoc {:bg "#0F131A" :fg "#BFBDB6"})
(vim.api.nvim_set_hl 0 :BlinkCmpDocBorder {:bg "#0F131A" :fg "#565B66"})
(vim.api.nvim_set_hl 0 :BlinkCmpSignatureHelp {:link :NormalFloat})
(vim.api.nvim_set_hl 0 :BlinkCmpSignatureHelpBorder {:link :FloatBorder})
(vim.api.nvim_set_hl 0 :BlinkCmpGhostText {:fg "#636A72"})
;
(vim.api.nvim_set_hl 0 :BlinkCmpKind {:link :Type})
(vim.api.nvim_set_hl 0 :BlinkCmpKindText {:fg "#BFBDB6"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindMethod {:fg "#FFB454"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindFunction {:fg "#FFB454"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindConstructor {:fg "#FF8F40"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindField {:fg "#E6B673"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindVariable {:fg "#BFBDB6"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindClass {:fg "#59C2FF"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindInterface {:fg "#59C2FF"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindModule {:fg "#39BAE6"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindProperty {:fg "#E6B673"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindUnit {:fg "#D2A6FF"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindValue {:fg "#D2A6FF"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindEnum {:fg "#59C2FF"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindKeyword {:fg "#FF8F40"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindSnippet {:fg "#95E6CB"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindColor {:fg "#F07178"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindFile {:fg "#565B66"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindReference {:fg "#F07178"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindFolder {:fg "#39BAE6"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindEnumMember {:fg "#D2A6FF"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindConstant {:fg "#D2A6FF"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindStruct {:fg "#59C2FF"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindEvent {:fg "#F07178"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindOperator {:fg "#F29668"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindTypeParameter {:fg "#59C2FF"})
(vim.api.nvim_set_hl 0 :BlinkCmpKindCopilot {:fg "#AAD94C"})

(let [nvim-icons (require :nvim-web-devicons)]
  (nvim-icons.setup {:color_icons true
                     :override_by_extension {:ign {:icon "󰈸"
                                                   :color "#702963"
                                                   :name :Ignis}}}))
