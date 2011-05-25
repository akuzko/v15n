module V15n::Rails
  module Routing
    def v15n
      match 'v15n/:action' => V15n::Rails::Controller
    end
  end
end