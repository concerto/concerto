module ApplicationHelper
    def nav_link_to(text, path, mobile = false)
        css = "rounded-md px-3 py-2 font-medium "
        css += (mobile ? "block text-medium " : "text-sm ")
        aria = {}
        if current_page?(path)
            css += " bg-gray-900 text-white"
            aria = { current: "page" }
        else
            css += " text-gray-300 hover:bg-gray-700 hover:text-white"
        end
        link_to(text, path, class: css, aria: aria)
    end
end
