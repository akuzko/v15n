#ApplicationController.send :include, V15n::Rails::Helper
#Cell::Base.send :include, V15n::Rails::Helper if defined? Cell::Base
ActionDispatch::Routing::Mapper.send :include, V15n::Rails::Routing
