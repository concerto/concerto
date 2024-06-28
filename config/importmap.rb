# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "stimulus-rails-nested-form" # @4.1.0
pin "@stimulus-components/dropdown", to: "@stimulus-components--dropdown.js" # @3.0.0
pin "stimulus-use" # @0.52.2
pin "@tailwindcss/forms", to: "@tailwindcss--forms.js" # @0.5.7
pin "mini-svg-data-uri" # @1.4.4
pin "picocolors" # @1.0.1
pin "tailwindcss/colors", to: "tailwindcss--colors.js" # @3.4.4
pin "tailwindcss/defaultTheme", to: "tailwindcss--defaultTheme.js" # @3.4.4
pin "tailwindcss/plugin", to: "tailwindcss--plugin.js" # @3.4.4
