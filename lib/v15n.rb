module V15n
  UNICODE_KEY_CHAR = 40960

  class << self
    attr_reader :keys, :values
    attr_accessor :secret

    def process controller
      preprocess controller
      yield
      postprocess controller
    end

    def preprocess controller
      enable!
      reset!(controller.request.xhr? ? controller.session[:v15n_index] : nil)
    end

    def postprocess controller
      if controller.request.xhr?
        if [:html, :js].include? controller.request.format.symbol
          js = <<-JS.html_safe
            if(typeof v15n != 'indefined') {
              v15n.addKeys(#{V15n.keys.to_json});
              v15n.addValues(#{V15n.values.to_json});
              v15n.process();
              v15n.panel.renderTranslations();
            }
          JS
          js = controller.view_context.javascript_tag{ js } if controller.request.format == :html
          controller.response.body += js
        end
      end
      controller.session[:v15n_index] = @index
    end

    def t key, options
      use(index(key), I18n.t(key, options))
    end

    def backend
      @backend ||= Backend.new
    end

    def enabled?
      @enabled
    end

    def disable!
      @enabled = false
    end

    def disabled_in? controller
      !controller.session[:v15n_enabled]
    end

    private

    def index key
      keys[use_index] = key unless keys.values.include? key
      index = keys.invert[key]
      values[index] = I18n.backend.backends.map{ |b| b.send :lookup, :fr, key }.compact.first || ''
      index
    end

    def use index, msg
      bchar = [index].pack "U"
      (bchar + msg + bchar).html_safe
    end

    def enable!
      @enabled = true
    end

    def reset! index = nil
      @index = index || UNICODE_KEY_CHAR - 1
      @keys = ActiveSupport::OrderedHash.new
      @values = {}
    end

    def use_index
      @index += 1
    end
  end

  autoload :Filter, 'v15n/filter'
  autoload :Backend, 'v15n/backend'
  autoload :Helper, 'v15n/helper'
  autoload :ViewHelper, 'v15n/helper'
  autoload :Routing, 'v15n/routing'
  autoload :Controller, 'v15n/controller'

  reset!
end
