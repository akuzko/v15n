module V15n::Rails
  module Processing
    def process controller
      preprocess controller
      yield
      postprocess controller
    end

    def disabled_in? controller
      !controller.session[:v15n_enabled]
    end

    private

    def preprocess controller
      enable!
      reset!(controller.request.xhr? ? controller.session[:v15n_index] : nil)
    end

    def postprocess controller
      if controller.request.xhr?
        append_xhr controller
      elsif controller.request.format == :html
        append_layout controller
      end
      controller.session[:v15n_index] = @index
    end

    def append_layout controller
      view = controller.view_context
      panel_html = [$/].tap do |content|
        content << view.stylesheet_link_tag("v15n")
        content << view.javascript_include_tag("v15n")
        content << view.javascript_tag do
          <<-JS.html_safe
            v15n.locale = '#{I18n.locale}';
            v15n.page = '#{view.controller_path}:#{view.action_name}';
            v15n.setKeys(#{@keys.to_json});
            v15n.setValues(#{@values.to_json});
            $(function() {
              v15n.process();
              v15n.panel.render();
            });
          JS
        end
        content << $/
      end.join($/)
      controller.response.body = controller.response.body.gsub(/()(?=<\/body>.*<\/html>$)/m, panel_html)
    end

    def append_xhr controller
      if [:html, :js].include? controller.request.format.symbol
        js = <<-JS.html_safe
          if(typeof v15n != 'indefined') {
            v15n.addKeys(#{@keys.to_json});
            v15n.addValues(#{@values.to_json});
            v15n.process();
            v15n.panel.renderTranslations();
          }
        JS
        js = controller.view_context.javascript_tag{ js } if controller.request.format == :html
        controller.response.body += js
      end
    end
  end
end
