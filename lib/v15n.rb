module V15n
  autoload :Rails, 'v15n/rails'
  autoload :Backend, 'v15n/backend'
  
  UNICODE_KEY_CHAR = 40960
  AUTH_STRATEGIES = [:secret, :http_basic].freeze
  extend Rails::Processing

  class << self
    attr_writer :secret, :username, :password
    attr_reader :authenticator

    @redis_db = 6
    attr_accessor :redis_db

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

    def setup
      yield self
    end

    def authentication_strategy= strategy
      raise 'Invalid authentication strategy. Available options are :secret, :http_basic' unless AUTH_STRATEGIES.include? strategy
      @authenticator = send "#{strategy}_authenticator"
    end

    private

    def index key
      @keys[use_index] = key unless @keys.values.include? key
      index = @keys.invert[key]
      @values[index] = I18n.backend.backends.map{ |b| b.send :lookup, I18n.locale, key }.compact.first || ''
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

    def secret_authenticator
      lambda{ |controller| controller.params[:secret] == @secret }
    end

    def http_basic_authenticator
      lambda { |controller|
        controller.authenticate_or_request_with_http_basic do |username, password|
          username == @username && password == @password
        end
      }
    end
  end

  #autoload :Filter, 'v15n/filter'
#  autoload :Helper, 'v15n/helper'
#  autoload :ViewHelper, 'v15n/helper'
#  autoload :Routing, 'v15n/routing'
#  autoload :Controller, 'v15n/controller'

  reset!
end
