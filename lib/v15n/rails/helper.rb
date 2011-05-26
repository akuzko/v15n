module V15n::Rails
  module Helper
    extend ActiveSupport::Concern
    included do
      helper_method :t
      around_filter V15n::Rails::Filter if respond_to? :around_filter
    end

    def t key, options = {}
      options[:default] ||= key[/\.?(?=[^\.]+$)(.+)/, 1]
      return I18n.t(key, options) unless V15n.enabled?
      V15n.t key, options
    end
  end
end
