require 'rails'

module V15n
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "This generator installs assets used for visual translation"
      source_root File.expand_path('../../../assets', __FILE__)

      def copy_assets
        say_status "copying", "assets needed for visual translation", :green
        copy_file "v15n.css", "public/stylesheets/v15n.css"
        copy_file "v15n.js", "public/javascripts/v15n.js"
        copy_file "v15n_save.png", "public/images/v15n_save.png"
        copy_file "v15n_delete.png", "public/images/v15n_delete.png"
      end

      def copy_initializer
        say_status "generating", "v15n initializer", :green
        template "../templates/v15n.rb", "config/initializers/v15n.rb"
      end
    end
  end
end
