class RichText < Content
    store_accessor :config, :render_as

    # render_as is anenum-like structure. Ideally we would use rails'
    # ActtiveRecord::Enum functionality, but it doesn't work store_accessor.
    def html? = render_as == "html"
    def plaintext? = render_as == "plaintext"

    def self.render_as
        { plaintext: "plaintext", html: "html" }
    end
end
