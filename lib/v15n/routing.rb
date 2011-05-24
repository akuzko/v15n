module V15n
  module Routing
    def v15n
      match 'v15n/:action' => V15n::Controller
    end
  end
end