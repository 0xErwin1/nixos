(let [conform (require :conform)
      util (require :conform.util)
      biome-config-files ["biome.json"
                          "biome.jsonc"
                          "biome.config.js"
                          "biome.config.cjs"
                          "biome.config.mjs"
                          "biome.config.ts"
                          "biome.config.cts"
                          "biome.config.mts"]
      default-formatters [:squeeze_blanks :trim_whitespace :trim_newlines]
      js-formatters [:biome :prettierd :prettier]]
  (conform.setup {:formatters_by_ft {:_ default-formatters
                                     :json [:prettierd :jq]
                                     :markdown [:prettierd]
                                     :ignis default-formatters
                                     :python [:isort :black]
                                     :go [:gofmt]
                                     :lua [:stylua]
                                     :fennel [:fnlfmt]
                                     :rust [:rustfmt]
                                     :toml [:rustfmt]
                                     :nix [:nixfmt]
                                     :zig [:zigfmt]
                                     :nasm [:asmfmt]
                                     :asm [:asmfmt]
                                     :c [:clang-format]
                                     :cpp [:clang-format]
                                     :cmake [:cmake-format]
                                     :make [:cmake-format]
                                     :bash [:shfmt]
                                     :sh [:shfmt]
                                     :shell [:shfmt]
                                     :elixir [:mix-format]
                                     :eelixir [:mix-format]
                                     :heex [:mix-format]
                                     :javascript js-formatters
                                     :typescript js-formatters
                                     :javascriptreact js-formatters
                                     :typescriptreact js-formatters
                                     :vue js-formatters
                                     :astro js-formatters}})
  (let [biome (. (. conform :formatters) :biome)]
    (when biome
      (tset biome :condition (util.root_file biome-config-files)))))

(let [wk (require :which-key)]
  (wk.add [{1 :<leader>cf
            2 "<cmd>lua require('conform').format({ async = true, lsp_format = 'fallback' })<CR>"
            :desc "Format code"
            :mode :n
            :group :Code}]))
