module V15n::Rails
  class Filter
    def self.filter controller
      V15n.disable!
      return yield if V15n.disabled_in?(controller) || controller.instance_of?(V15n::Rails::Controller)
      V15n.process(controller){ yield }
    end
  end
end
