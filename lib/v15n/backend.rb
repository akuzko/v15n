require 'redis'
module V15n
  class Backend < I18n::Backend::KeyValue
    def initialize
      super redis
    end

    def custom_translations page
      @redis.smembers(page).inject({}){ |res, key| res[key] = @redis[key] || ''; res }
    end

    delegate :sadd, :srem, :to => :redis

    private

    def redis
      @redis ||= Redis.new(:db => 9)
    end
  end
end