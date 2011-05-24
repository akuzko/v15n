module V15n
  class Controller < ApplicationController
    before_filter :enabled?, :except => :enable

    def save
      params[:value] = nil if params[:value].empty?
      V15n.backend.store_translations(params[:locale], {params[:key] => params[:value]}, :escape => false)
      render :text => 'Saved'
    end

    def custom
      translations = V15n.backend.custom_translations params[:page]
      render :json => translations
    end

    def custom_sadd
      V15n.backend.sadd params[:page], params[:key]
      render :text => ''
    end

    def custom_srem
      V15n.backend.srem params[:page], params[:key]
      render :text => ''
    end

    def enable
      session[:v15n_enabled] = true if params[:secret] == V15n.secret
      redirect_to root_path
    end

    def disable
      session[:v15n_enabled] = nil
      redirect_to root_path
    end

    private

    def enabled?
      render :text => 'Access denied' unless session[:v15n_enabled]
    end
  end
end