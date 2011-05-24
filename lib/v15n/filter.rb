module V15n
  class Filter
    def self.filter controller
      V15n.disable!
      return yield if V15n.disabled_in?(controller) || controller.instance_of?(V15n::Controller)
#      V15n.process controller do
#        yield
#      end
      V15n.process controller
    end
  end
end
