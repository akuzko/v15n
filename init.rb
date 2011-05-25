V15n.secret = '824f1f5f72ce727b19fcfdf54b16d740d4b197c319aaeb1027dff426ea801aa6342ad5d92dcd0a182b1d3533eb096375ae95203ffa31c66aaa993e17bd008b5c'

#ApplicationController.send :include, V15n::Rails::Helper
#Cell::Base.send :include, V15n::Rails::Helper if defined? Cell::Base
#ActionView::Base.send :include, V15n::Rails::ViewHelper
ActionDispatch::Routing::Mapper.send :include, V15n::Rails::Routing

I18n.backend = I18n::Backend::Chain.new(V15n.backend, I18n.backend)
