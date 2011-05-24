module V15n
  module Helper
    extend ActiveSupport::Concern
    included{ helper_method :t }

    def t key, options = {}
      options[:default] ||= key[/\.?(?=[^\.]+$)(.+)/, 1]
      return I18n.t(key, options) unless V15n.enabled?
      V15n.t key, options
    end
  end

  module ViewHelper
    def v15n
      return unless V18n.enabled?
      c = ''.tap do |content|
        content << stylesheet_link_tag("v15n")
        content << javascript_include_tag("v15n")
        content << javascript_tag do
          <<-JS.html_safe
            v15n.locale = '#{I18n.locale}';
            v15n.page = '#{controller_path}:#{action_name}';
            v15n.setKeys(#{V15n.keys.to_json});
            v15n.setValues(#{V15n.values.to_json});
            v15n.process();
            v15n.panel.render();
          JS
        end
      end
      raw c
    end
  end
end
